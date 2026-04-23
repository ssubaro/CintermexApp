const fs = require('fs');
const env = fs.readFileSync('.env', 'utf8').split('\n').reduce((acc, line) => {
  const [key, ...val] = line.split('=');
  if (key) acc[key.trim()] = val.join('=').trim();
  return acc;
}, {});

const url = env.SUPABASE_URL + '/rest/v1/tickets?select=*';
const key = env.SUPABASE_ANON_KEY;

fetch(url, { headers: { 'apikey': key, 'Authorization': `Bearer ${key}` } })
.then(res => res.json())
.then(data => console.log(JSON.stringify(data, null, 2)))
.catch(err => console.error(err));
