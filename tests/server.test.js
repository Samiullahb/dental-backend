const test = require('node:test');
const assert = require('node:assert/strict');
const { validateAppointment } = require('../server');

test('rejects incomplete appointment', () => {
  assert.equal(validateAppointment({ patientName: 'Test' }), 'patientName, date and time are required');
});

test('accepts valid appointment', () => {
  assert.equal(validateAppointment({ patientName: 'Test', date: '2026-09-01', time: '10:00' }), null);
});
