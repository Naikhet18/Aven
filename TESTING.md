# Testing Strategy

## Automated Tests
- **Unit Tests**: Test domain models, calculation logic (e.g., cart totals, tax, discounts), and data mapping (JSON to model).
- **Widget Tests**: Test the UI components, ensuring buttons trigger correct state changes and UI renders correctly given specific data.
- **Integration Tests**: Test the full flow from Order Creation to Kitchen Status change to Billing and Payment.

### Key Scenarios to Test
1. **Offline Order Creation**: Create an order while the internet is disconnected. Verify it saves locally and queues for sync.
2. **Duplicate Prevention**: Create two orders rapidly on different devices simultaneously. Verify unique UUIDs prevent conflicts.
3. **Sync Recovery**: Disconnect internet, make changes, reconnect, and verify all pending changes sync successfully to Supabase and other devices.

## Manual Testing
1. **Multi-device Sync Test**:
   - Device A (Android) and Device B (iPhone) logged into the same business.
   - Device A creates an order. Verify it appears on Device B instantly.
   - Device B updates the order status to "PREPARING". Verify Device A sees the change instantly.
2. **Payment Tracking**:
   - Add a partial payment (Cash) on Device A.
   - Verify Device B sees the remaining balance correctly.
   - Complete the payment (UPI) on Device B. Verify Device A reflects the Paid status.
