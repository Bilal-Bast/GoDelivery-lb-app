# GoDelivery Flutter → backend API map

Source of truth: `GoDelivery-lb/app.js`, `src/routes/`, `src/controllers/`, and
`prisma/schema.prisma`. All protected calls accept `Authorization: Bearer <JWT>`;
the same middleware also accepts the web app's `token` cookie. JWT roles are
lowercase `admin`, `merchant`, and `driver`.

| Flutter feature | HTTP contract | Backend route/controller | Prisma/data source |
|---|---|---|---|
| Login | `POST /api/auth/login` `{username,password}` → `{success,token,refreshToken,role,username,user}` | `auth.routes.js` → `auth.controller.login` | `User`; bcrypt + 30-minute JWT. `refreshToken` is the same JWT; there is no refresh endpoint. |
| Restore session/profile | `GET /api/auth/me` → user object | `auth.routes.js` → `auth.controller.getMe` | `User` |
| Admin users | `GET /api/users` → user array | `user.routes.js` → `user/api.getUsers` | `User`, `DeliveryCharge` |
| Add users | `POST /api/users/add-admin`, `/add-merchant`, `/add-driver` | `user.routes.js` → `addAdmin`/`addMerchant`/`addDriver` | `User`, optionally `DeliveryCharge` |
| Edit/delete users | `GET/PUT/DELETE /api/users/:id`; specialized `PUT /merchants/:id`, `/drivers/:id` | `user.routes.js` → user API controllers | `User` and dependent finance/order relations |
| Admin orders | `GET /api/orders?page=&limit=` → `{data,pagination}` | `order.routes.js` → `order/api.getOrders` | `Order`, merchant/driver `User`, `CollectionOrder` |
| Merchant orders | `GET /api/orders/my` → compact order array | `order.routes.js` → `getOrdersByCurrentMerchant` | `Order`, `PaymentOrder` |
| Driver orders | `GET /api/drivers/orders` → compact order array | `driver.routes.js` → `driver.controller.getDriverOrders` | `Order` filtered to assigned/current or recently finished |
| Order detail | `GET /api/orders/:id` → compact order + `history` | `order.routes.js` → `getOrderById` | `Order`, `OrderHistory`, settlement links |
| Create order | `POST /api/orders` with `{id,m,c:{f,l,p,loc:{d,cty}},pr:{t,d},s?,e?,eN?}` → `{message,order}` | `order.routes.js` → `createOrder` → `order/mappers.buildOrderCreateData` | `Order`, `OrderHistory`; merchant resolved by username |
| Update status | `PATCH /api/orders/:id/status` `{s:0..6,note?,cancelledBy?}` → `{message,order}` | `order.routes.js` → `updateOrderStatus` | `Order`, `OrderHistory` |
| Driver list/stats | `GET /api/drivers` (admin), `GET /api/drivers/stats` (driver) | `driver.routes.js` → `getDrivers`/`getDriverStats` | `User`, `Order` |
| Analytics | `GET /api/analytics?startDate=&endDate=&status=&merchant=` → `{summary,revenueByDay,ordersByDay,topLocations,topMerchants,topDrivers,recentOrders,merchants}` | inline `app.js` route → `analytics.controller.getAnalytics` | Aggregates over `Order` and `User` |
| Finance balances | `GET /api/finance/balances` → `{merchants,drivers,totals}` | `finance.routes.js` → `finance.controller.getBalances` | `Order`, `User`, collection/payment links |
| Collect driver | `POST /api/finance/collect-driver` `{driverUsername,paymentMethod?}` | `finance.routes.js` → `collectFromDriver` | `DriverCollection`, `CollectionOrder`, `FinanceTransaction`, `FinanceAudit`, `OrderHistory`, `Order` |
| Pay merchant | `POST /api/finance/pay-merchant` `{merchantUsername,paymentMethod?}` | `finance.routes.js` → `payMerchant` | `MerchantPayment`, `PaymentOrder`, `FinanceTransaction`, `FinanceAudit`, `OrderHistory`, `Order` |
| Prepaid payment | `POST /api/finance/pay-prepaid-merchant` `{merchantUsername,amount,paymentMethod?,notes?}` | `finance.routes.js` → `payPrepaidMerchant` | `MerchantPayment`, `FinanceTransaction`, `FinanceAudit` |
| Collection history | `GET /api/collections?page=&limit=&driver=` → `{data,pagination}` | `collection.routes.js` → `collection/collectionController.getCollections` | `DriverCollection`, `CollectionOrder`, `User`, `Order` |
| Payment history | `GET /api/payments?page=&limit=&merchant=&isAdvance=` → `{data,pagination}` | `payment.routes.js` → `payment/paymentController.getPayments` | `MerchantPayment`, `PaymentOrder`, `User`, `Order` |
| Locations/settings | `GET /api/locations` → `[{id,district:{en,ar},cities:[{en,ar}],...}]`; admin `POST /api/locations` `{district,cityEn,cityAr?}`; `DELETE /api/locations/:id` | `location.routes.js` → `location.controller` | `District`, `City` |

## Compact order status contract

`s` is numeric: `0 Warehouse`, `1 New`, `2 Picked Up`, `3 Delivered`,
`4 Cancelled`, `5 Paid`, `6 Collected`. Prisma stores the corresponding enums
`WAREHOUSE`, `NEW`, `Picked_up`, `DELIVERED`, `Canceled`, `Paid`, `COLLECTED`.

## Authorization and current backend gaps

- Admin-only: all users, all orders, driver list, analytics, finance, collection
  history, payment history, and location mutation.
- Merchant: own orders, merchant-scoped order reads, create order, and order history.
- Driver: assigned orders, driver stats, order detail, and status updates.
- The backend does **not** expose `/api/auth/refresh-token`, singular
  `/api/driver/*` or `/api/merchant/*` routes, split location district/city
  routes, driver self-service collection history, or merchant self-service
  balance/payment history. Flutter must not call those paths. Adding the final
  two self-service features would require an explicit backend authorization/API
  decision.
- There is no generic settings JSON endpoint. The API-backed settings surface is
  currently locations; other settings behavior belongs to SSR routes/forms.
