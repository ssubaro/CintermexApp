import { createClient } from "https://esm.sh/@supabase/supabase-js@2.7.1"

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
// SECURITY: This secret must be configured in Supabase secrets, NOT in .env client-side.
// Get it from your Conekta dashboard -> Webhooks -> Signing Secret
const CONEKTA_WEBHOOK_SECRET = Deno.env.get('CONEKTA_WEBHOOK_SECRET')

const supabase = createClient(SUPABASE_URL!, SUPABASE_SERVICE_ROLE_KEY!)

/**
 * Verifies the HMAC-SHA256 signature sent by Conekta in the
 * 'Conekta-Signature' header to prevent spoofed webhook requests.
 */
async function verifyConektaSignature(
    rawBody: string,
    signatureHeader: string | null,
    secret: string
): Promise<boolean> {
    if (!signatureHeader) return false

    const encoder = new TextEncoder()
    const keyData = encoder.encode(secret)
    const messageData = encoder.encode(rawBody)

    const cryptoKey = await crypto.subtle.importKey(
        "raw",
        keyData,
        { name: "HMAC", hash: "SHA-256" },
        false,
        ["sign"]
    )

    const signature = await crypto.subtle.sign("HMAC", cryptoKey, messageData)
    const hashArray = Array.from(new Uint8Array(signature))
    const computedHex = hashArray.map(b => b.toString(16).padStart(2, '0')).join('')

    // Conekta may send "t=<timestamp>,v1=<hash>" or just the hash
    const receivedHash = signatureHeader.includes('v1=')
        ? signatureHeader.split('v1=')[1]?.split(',')[0] ?? ''
        : signatureHeader

    // Constant-time comparison to prevent timing attacks
    if (computedHex.length !== receivedHash.length) return false
    let diff = 0
    for (let i = 0; i < computedHex.length; i++) {
        diff |= computedHex.charCodeAt(i) ^ receivedHash.charCodeAt(i)
    }
    return diff === 0
}

Deno.serve(async (req) => {
    try {
        const rawBody = await req.text()

        // --- SECURITY: Verify webhook signature before processing ---
        if (CONEKTA_WEBHOOK_SECRET) {
            const signature = req.headers.get('Conekta-Signature')
            const isValid = await verifyConektaSignature(rawBody, signature, CONEKTA_WEBHOOK_SECRET)
            if (!isValid) {
                console.warn("Webhook rejected: invalid signature")
                return new Response(JSON.stringify({ error: 'Invalid signature' }), { status: 401 })
            }
        } else {
            // Log a warning in development if the secret is not configured
            console.warn("CONEKTA_WEBHOOK_SECRET not set — signature verification skipped (INSECURE)")
        }

        const payload = JSON.parse(rawBody)
        // Log only the event type, NOT the full payload (which may contain PII)
        console.log("Webhook received, type:", payload.type)

        if (payload.type === 'order.paid') {
            const order = payload.data?.object
            const metadata = order?.metadata

            if (metadata && metadata.user_id && metadata.event_id) {
                const orderId = order.id as string

                // --- SECURITY: Idempotency check — avoid duplicate tickets for same order ---
                const { data: existing } = await supabase
                    .from('tickets')
                    .select('id')
                    .eq('conekta_order_id', orderId)
                    .maybeSingle()

                if (existing) {
                    console.log("Ticket already exists for order:", orderId, "— skipping")
                    return new Response(JSON.stringify({ received: true, duplicate: true }), {
                        status: 200,
                        headers: { "Content-Type": "application/json" }
                    })
                }

                const { error } = await supabase
                    .from('tickets')
                    .insert({
                        user_id: metadata.user_id,
                        event_id: metadata.event_id,
                        quantity: parseInt(metadata.quantity) || 1,
                        selected_date: metadata.selected_date,
                        ticket_type_id: metadata.ticket_type_id || null,
                        price_paid: order.amount / 100, // Conekta: cents to MXN
                        status: 'active',
                        payment_status: 'completed',
                        conekta_order_id: orderId,
                    })

                if (error) {
                    console.error("Error inserting ticket:", error.code, error.message)
                    return new Response(JSON.stringify({ error: 'Failed to create ticket' }), { status: 500 })
                }

                console.log("Ticket created successfully for order:", orderId)
            } else {
                console.warn("order.paid received but metadata is missing user_id or event_id:", JSON.stringify(metadata))
            }
        }

        return new Response(JSON.stringify({ received: true }), {
            status: 200,
            headers: { "Content-Type": "application/json" }
        })

    } catch (error) {
        // Log the real error server-side, return a generic message to the caller
        console.error("Webhook processing error:", error instanceof Error ? error.message : String(error))
        return new Response(JSON.stringify({ error: 'Internal server error' }), { status: 500 })
    }
})
