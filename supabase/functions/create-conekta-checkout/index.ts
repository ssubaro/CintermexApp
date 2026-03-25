const CONEKTA_API_KEY = Deno.env.get('CONEKTA_API_KEY')

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// Function to remove accents and special characters to comply with Conekta validation
const sanitizeName = (name: string): string => {
    if (!name) return "Cliente Cintermex";
    return name
        .normalize("NFD")
        .replace(/[\u0300-\u036f]/g, "") // Remove accents
        .replace(/[^a-zA-Z0-9 ]/g, "")   // Keep only alphanumeric and spaces
        .trim() || "Cintermex Item";
};

Deno.serve(async (req) => {
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders })
    }

    try {
        const rawBody = await req.json()
        const {
            event_id,
            event_title,
            unit_price,
            quantity,
            customer_email,
            user_id,
            selected_date,
            success_url,
            failure_url
        } = rawBody

        const sanitizedEventTitle = sanitizeName(event_title);

        // Official structure for POST /checkouts (Payment Links) - API v2.1.0
        const body = {
            name: `Compra ${sanitizedEventTitle}`.substring(0, 40),
            type: "PaymentLink",
            recurrent: false,
            expires_at: Math.floor(Date.now() / 1000) + (3600 * 24 * 7), // 7 days expiration
            allowed_payment_methods: ["card", "cash", "bank_transfer"],
            needs_shipping_contact: false,
            order_template: {
                currency: "MXN",
                metadata: {
                    user_id: user_id,
                    event_id: event_id,
                    selected_date: selected_date,
                    quantity: quantity.toString()
                },
                customer_info: {
                    name: "Cintermex Customer",
                    email: customer_email || 'customer@example.com',
                    phone: "5555555555"
                },
                line_items: [{
                    name: sanitizedEventTitle.substring(0, 40),
                    unit_price: Math.round((unit_price || 0) * 100),
                    quantity: quantity || 1,
                }]
            }
        }

        const response = await fetch("https://api.conekta.io/checkouts", {
            method: "POST",
            headers: {
                "Accept": "application/vnd.conekta-v2.1.0+json",
                "Content-Type": "application/json",
                "Authorization": `Bearer ${CONEKTA_API_KEY}`
            },
            body: JSON.stringify(body)
        })

        const data = await response.json()

        if (!response.ok) {
            const detail = data.details?.[0];
            const errorMsg = detail ? detail.message : (data.message || 'Error en Conekta');
            throw new Error(errorMsg)
        }

        return new Response(
            JSON.stringify({ url: data.url || data.http_redirect_url }),
            { headers: { ...corsHeaders, "Content-Type": "application/json" } }
        )

    } catch (error) {
        const errorMsg = (error instanceof Error) ? error.message : "Unknown error";
        return new Response(
            JSON.stringify({ error: errorMsg }),
            { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        )
    }
})
