import { useEffect, useState } from 'react';
import api from '../api/client';
import { useAuth } from '../context/AuthContext';

export default function StationServices() {
  const { staff } = useAuth();
  const [stations, setStations] = useState([]);
  const [prices, setPrices] = useState([]);

  useEffect(() => {
    api.get('/staff/stations').then((r) => setStations(r.data.data.stations));
    api.get('/staff/stations/compare').then((r) => setPrices(r.data.data.prices));
  }, []);

  const myStation = stations.find((s) => s.station_id === staff?.station_id);

  return (
    <div>
      <h2>Station Services</h2>
      {myStation && (
        <>
          <h3>My Station: {myStation.name}</h3>
          <iframe
            title="map"
            width="100%"
            height="300"
            style={{ border: 0, marginBottom: 20 }}
            src={`https://maps.google.com/maps?q=${myStation.latitude},${myStation.longitude}&z=15&output=embed`}
          />
        </>
      )}
      <h3>Compare Fuel Prices (All Stations)</h3>
      <table border="1" cellPadding="8" style={{ borderCollapse: 'collapse', width: '100%' }}>
        <thead>
          <tr><th>Station</th><th>Brand</th><th>Fuel Type</th><th>Price</th><th>Available</th></tr>
        </thead>
        <tbody>
          {prices.map((p) => (
            <tr key={p.price_id} style={{ background: p.station_id === staff?.station_id ? '#FFF0EA' : 'white' }}>
              <td>{p.station_name}</td>
              <td>{p.fuel_brand}</td>
              <td>{p.fuel_type}</td>
              <td>₱{p.price}</td>
              <td>{p.availability ? 'Yes' : 'No'}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}