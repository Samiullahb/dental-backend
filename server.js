const crypto = require('node:crypto');

const TABLE_NAME = process.env.TABLE_NAME || 'appointments';

const response = (statusCode, body) => ({
  statusCode,
  headers: { 'content-type': 'application/json' },
  body: JSON.stringify(body)
});

function parseBody(event) {
  if (!event.body) return {};
  try { return JSON.parse(event.body); } catch { return null; }
}

function validateAppointment(body) {
  if (!body || typeof body !== 'object') return 'Invalid JSON body';
  if (!body.patientName || !body.date || !body.time) return 'patientName, date and time are required';
  return null;
}

async function handler(event, context, dependencies = {}) {
  const method = event?.requestContext?.http?.method || event?.httpMethod;
  const path = event?.rawPath || event?.path;

  if (method === 'GET' && path === '/health') return response(200, { status: 'healthy', service: 'dental-backend' });

  const dynamo = dependencies.dynamo;
  if (!dynamo) throw new Error('DynamoDB dependency is not configured');

  if (method === 'POST' && path === '/appointments') {
    const body = parseBody(event);
    const error = validateAppointment(body);
    if (error) return response(400, { error });
    const appointment = { id: crypto.randomUUID(), patientName: body.patientName, date: body.date, time: body.time, status: 'scheduled', createdAt: new Date().toISOString() };
    await dynamo.put({ TableName: TABLE_NAME, Item: appointment });
    return response(201, appointment);
  }

  if (method === 'GET' && path === '/appointments') {
    const result = await dynamo.scan({ TableName: TABLE_NAME });
    return response(200, result.Items || []);
  }

  return response(404, { error: 'Route not found' });
}

module.exports = { handler, validateAppointment };
