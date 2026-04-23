const fs = require('fs');
const env = fs.readFileSync('.env', 'utf8').split('\n').reduce((acc, line) => {
  const [key, ...val] = line.split('=');
  if (key) acc[key.trim()] = val.join('=').trim();
  return acc;
}, {});

const SUPABASE_URL = env.SUPABASE_URL;
const SUPABASE_ANON_KEY = env.SUPABASE_ANON_KEY;

const headers = {
  'apikey': SUPABASE_ANON_KEY,
  'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
  'Content-Type': 'application/json',
  'Prefer': 'return=representation'
};

async function testTrigger() {
  const email = `testuser_${Date.now()}@example.com`;
  const password = 'testpassword123';
  
  // Sign up
  const authRes = await fetch(`${SUPABASE_URL}/auth/v1/signup`, {
    method: 'POST',
    headers,
    body: JSON.stringify({ email, password })
  });
  const authData = await authRes.json();
  if (!authRes.ok) {
    console.error("Auth err:", authData);
    return;
  }
  const userId = authData.user.id;
  const userToken = authData.session.access_token;
  console.log("Created user:", userId);

  const authHeaders = { ...headers, 'Authorization': `Bearer ${userToken}` };

  // Fetch event
  const evRes = await fetch(`${SUPABASE_URL}/rest/v1/events?select=id&limit=1`, { headers: authHeaders });
  const events = await evRes.json();
  const eventId = events?.[0]?.id;
  
  if (!eventId) {
    console.log("No events found");
    return;
  }

  // Insert Order
  const orderRes = await fetch(`${SUPABASE_URL}/rest/v1/orders`, {
    method: 'POST',
    headers: authHeaders,
    body: JSON.stringify({
      user_id: userId,
      event_id: eventId,
      quantity: 1,
      unit_price: 100,
      subtotal: 100,
      total: 100,
      status: 'pending'
    })
  });
  const orderData = await orderRes.json();
  console.log("Order Insert Result:", Array.isArray(orderData) ? "Success" : orderData);

  // Check tickets
  const ticketRes = await fetch(`${SUPABASE_URL}/rest/v1/tickets?user_id=eq.${userId}&select=*`, { headers: authHeaders });
  const tickets = await ticketRes.json();
  
  console.log("Tickets found after order insert:", tickets?.length || 0);
  if (tickets?.length > 0) {
    console.log("Trigger IS creating tickets!");
    console.log(tickets);
  } else {
    console.log("No trigger spotted on order insert.");
  }
}

testTrigger();
