import { useState } from 'react';
import api from '../api/client';

export default function Notifications() {
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [status, setStatus] = useState('');

  async function handleSend(e) {
    e.preventDefault();
    setStatus('Sending...');
    try {
      const res = await api.post('/staff/notifications/broadcast', { title, body });
      setStatus(`Sent to ${res.data.data.sent} device(s).`);
      setTitle('');
      setBody('');
    } catch (err) {
      setStatus(err.response?.data?.message || 'Failed to send');
    }
  }

  return (
    <div style={{ maxWidth: 400 }}>
      <h2>Send Notification</h2>
      <form onSubmit={handleSend}>
        <input placeholder="Title" value={title} onChange={(e) => setTitle(e.target.value)} style={{ width: '100%', padding: 8, marginBottom: 8 }} />
        <textarea placeholder="Message" value={body} onChange={(e) => setBody(e.target.value)} style={{ width: '100%', padding: 8, marginBottom: 8, minHeight: 80 }} />
        <button type="submit">Send to All Customers</button>
      </form>
      {status && <p>{status}</p>}
    </div>
  );
}