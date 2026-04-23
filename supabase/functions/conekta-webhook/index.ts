import { createClient } from "https://esm.sh/@supabase/supabase-js@2.7.1"

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

const supabase = createClient(SUPABASE_URL!, SUPABASE_SERVICE_ROLE_KEY!)

Deno.serve(async (req) => {
    try {
        const payload = await req.json()
        console.log("Webhook received:", JSON.stringify(payload))

        // Conekta sends 'order.paid' when the payment is successful
        if (payload.type === 'order.paid') {
            const order = payload.data.object
            const metadata = order.metadata

            if (metadata && metadata.user_id && metadata.event_id) {
                console.log("Inserting ticket for user:", metadata.user_id)

                const { data, error } = await supabase
                    .from('tickets')
                    .insert({
                        user_id: metadata.user_id,
                        event_id: metadata.event_id,
                        quantity: parseInt(metadata.quantity) || 1,
                        selected_date: metadata.selected_date,
                        ticket_type_id: metadata.ticket_type_id,
                        price_paid: order.amount / 100, // Conekta cents to MXN
                        status: 'valid',
                        payment_status: 'completed',
                    })

                if (error) {
                    console.error("Error inserting ticket:", error)
                    return new Response(JSON.stringify({ error: error.message }), { status: 500 })
                }

                console.log("Ticket inserted successfully:", data)
            }
        }

        return new Response(JSON.stringify({ received: true }), {
            status: 200,
            headers: { "Content-Type": "application/json" }
        })

    } catch (error) {
        console.error("Webhook error:", error.message)
        return new Response(JSON.stringify({ error: error.message }), { status: 400 })
    }
})
