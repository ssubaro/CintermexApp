import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

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

    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
        return new Response(
            JSON.stringify({ error: 'No se proporcionó token de autorización' }),
            { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
    }

    // Initialize Supabase Client to verify the user
    const supabaseClient = createClient(
        Deno.env.get('SUPABASE_URL') ?? '',
        Deno.env.get('SUPABASE_ANON_KEY') ?? '',
        { global: { headers: { Authorization: authHeader } } }
    )

    // Verify user identity
    const { data: { user }, error: authError } = await supabaseClient.auth.getUser()
    if (authError || !user) {
        return new Response(
            JSON.stringify({ error: 'Token inválido o sesión expirada' }),
            { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
    }

    try {
        const rawBody = await req.json()
        const {
            event_id,
            event_title,
            unit_price,
            quantity,
            customer_email,
            customer_name,
            user_id,
            selected_date,
            success_url,
            failure_url
        } = rawBody

        const sanitizedEventTitle = sanitizeName(event_title);
        const sanitizedCustomerName = sanitizeName(customer_name || 'Cliente Cintermex');

        // Official structure for POST /checkouts (Payment Links) - API v2.1.0
        const body = {
            name: `Boletos - ${sanitizedEventTitle}`.substring(0, 40),
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
                    name: sanitizedCustomerName.substring(0, 40),
                    email: customer_email || 'customer@example.com',
                    phone: "5555555555"
                },
                line_items: [{
                    name: `Boleto: ${sanitizedEventTitle}`.substring(0, 60),
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
