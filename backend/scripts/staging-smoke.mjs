const baseUrl = process.env.STAGING_API_URL;

if (!baseUrl) {
  console.error('STAGING_API_URL is required');
  process.exit(1);
}

const normalized = baseUrl.replace(/\/$/, '');

async function check(path, expectedStatus = 200) {
  const response = await fetch(`${normalized}${path}`);
  if (response.status !== expectedStatus) {
    const body = await response.text();
    throw new Error(`${path} returned ${response.status}, expected ${expectedStatus}. Body: ${body.slice(0, 500)}`);
  }
  return response;
}

await check('/api/health');
await check('/api/openapi.json');

const protectedResponse = await fetch(`${normalized}/api/pets`);
if (protectedResponse.status !== 401) {
  throw new Error(`/api/pets without JWT returned ${protectedResponse.status}, expected 401`);
}

console.log('Staging smoke test passed: health, OpenAPI and auth boundary are healthy.');
