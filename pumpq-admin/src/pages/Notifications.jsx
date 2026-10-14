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
      setStatus(`Sent to ${res.data.data.sent} device(s)`);
      setTitle(''); setBody('');
    } catch (err) {
      setStatus(err.response?.data?.message || 'Failed to send');
    }
  }

  return (
    <div>
      <h2>Notifications</h2>
      <p>Send a push notification to all PumpQ customers</p>

      <div style={{ display: 'flex', gap: 20, marginTop: 20 }}>
        <div className="card" style={{ flex: 1.2 }}>
          <h3>Compose Notification</h3>
          <form onSubmit={handleSend}>
            <label style={{ fontSize: 12, fontWeight: 600, color: '#444' }}>Title</label>
            <input value={title} onChange={(e) => setTitle(e.target.value)} style={{ width: '100%', marginTop: 6, marginBottom: 16 }} />
            <label style={{ fontSize: 12, fontWeight: 600, color: '#444' }}>Message</label>
            <textarea value={body} onChange={(e) => setBody(e.target.value)} rows={5} style={{ width: '100%', marginTop: 6, marginBottom: 16, resize: 'vertical' }} />
            <button type="submit">Send to All Customers</button>
            {status && <p style={{ marginTop: 12, color: '#E8450A', fontSize: 13 }}>{status}</p>}
          </form>
        </div>
        <div className="card" style={{ flex: 1, background: '#1A1A1A', color: '#fff' }}>
          <h3 style={{ color: '#fff' }}>Preview</h3>
          <div style={{ background: '#2A2A2A', borderRadius: 12, padding: 16, marginTop: 10 }}>
            <p style={{ fontSize: 11, color: '#E8450A', fontWeight: 600 }}>PUMPQ</p>
            <p style={{ color: '#fff', fontWeight: 600, margin: '4px 0' }}>{title || 'Notification title'}</p>
            <p style={{ color: '#bbb', fontSize: 13 }}>{body || 'Your message will appear here'}</p>
          </div>
          <p style={{ color: '#888', fontSize: 12, marginTop: 16 }}>Delivered instantly to every customer with the PumpQ app installed.</p>
        </div>
      </div>
    </div>
  );
}