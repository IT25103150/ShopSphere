<#
  ShopSphere end-to-end API tests (PowerShell 7+).
  Run with the backend started and the database freshly seeded:
      pwsh -File scripts\api-tests.ps1
  It changes data (creates orders, adjusts stock...). Run RESET_DATABASE.bat afterwards to restore the seed state.
#>
param([string]$Base = 'http://localhost:8080')
$ErrorActionPreference = 'Stop'
$script:pass = 0; $script:fail = 0
Add-Type -AssemblyName System.Net.Http

function Call($method, $path, $body = $null, $token = $null) {
    $h = @{}
    if ($token) { $h['Authorization'] = "Bearer $token" }
    $p = @{ Uri = "$Base$path"; Method = $method; Headers = $h; SkipHttpErrorCheck = $true; ContentType = 'application/json' }
    if ($null -ne $body) { $p['Body'] = ($body | ConvertTo-Json -Depth 8) }
    $r = Invoke-WebRequest @p
    $j = $null
    if ($r.Content -and ($r.Headers['Content-Type'] -match 'json')) { $j = $r.Content | ConvertFrom-Json }
    [pscustomobject]@{ Code = [int]$r.StatusCode; Json = $j; Raw = $r.Content; Headers = $r.Headers }
}
function Check($name, $cond, $detail = '') {
    if ($cond) { $script:pass++; Write-Host "  PASS  $name" -ForegroundColor Green }
    else { $script:fail++; Write-Host "  FAIL  $name  $detail" -ForegroundColor Red }
}
function Section($t) { Write-Host "`n== $t" -ForegroundColor Cyan }
function Login($email) {
    $r = Call POST '/api/auth/login' @{ email = $email; password = 'Demo@123' }
    if ($r.Code -ne 200) { throw "Login failed for $email ($($r.Code))" }
    $r.Json.accessToken
}
function Stock($pid_, $tok) { (Call GET "/api/inventory/$pid_" $null $tok).Json.quantity }
function Card($number = '4111111111111111') { @{ cardHolder = 'Test User'; cardNumber = $number; expiryMonth = 12; expiryYear = 2030; cvv = '123' } }
function Checkout($tok, $coupon = $null, $card = $null) {
    Call POST '/api/checkout' @{ email = 'customer@shopsphere.lk'; firstName = 'Nimal'; lastName = 'Perera'; address = '45 Galle Road'; apartment = 'Apt 3B';
        city = 'Colombo'; postalCode = '00300'; country = 'Sri Lanka'; phone = '0771234505'; secondaryPhone = ''; couponCode = $coupon;
        payment = $(if ($card) { $card } else { Card }) } $tok
}

Section 'Authentication & roles'
$admin = Login 'admin@shopsphere.lk'; $staff = Login 'staff@shopsphere.lk'; $wh = Login 'warehouse@shopsphere.lk'
$dlv = Login 'delivery@shopsphere.lk'; $cust = Login 'customer@shopsphere.lk'; $cust2 = Login 'kavindi@shopsphere.lk'
Check 'all 6 seeded demo logins work' $true
Check 'wrong password -> 401' ((Call POST '/api/auth/login' @{ email = 'customer@shopsphere.lk'; password = 'nope' }).Code -eq 401)
Check 'unknown user -> 401' ((Call POST '/api/auth/login' @{ email = 'nobody@x.lk'; password = 'Demo@123' }).Code -eq 401)
Check 'login validation -> 400' ((Call POST '/api/auth/login' @{ email = 'bad'; password = '' }).Code -eq 400)
$me = Call GET '/api/users/me' $null $admin
Check 'GET /users/me returns ADMIN role' ($me.Json.role -eq 'ADMIN')
$lr = Call POST '/api/auth/login' @{ email = 'admin@shopsphere.lk'; password = 'Demo@123' }
$rf = Call POST '/api/auth/refresh' @{ refreshToken = $lr.Json.refreshToken }
Check 'refresh token issues a new access token' ($rf.Code -eq 200 -and $rf.Json.accessToken)
Check 'access token is rejected as refresh token' ((Call POST '/api/auth/refresh' @{ refreshToken = $lr.Json.accessToken }).Code -eq 401)
Check 'logout -> 204' ((Call POST '/api/auth/logout' $null $admin).Code -eq 204)

Section 'Authorization (wrong role -> 401/403)'
Check 'anonymous cart -> 401' ((Call GET '/api/cart').Code -eq 401)
Check 'anonymous POST product -> 401' ((Call POST '/api/products' @{}).Code -eq 401)
Check 'customer POST product -> 403' ((Call POST '/api/products' @{ name = 'x' } $cust).Code -eq 403)
Check 'customer analytics -> 403' ((Call GET '/api/analytics/dashboard' $null $cust).Code -eq 403)
Check 'customer inventory -> 403' ((Call GET '/api/inventory' $null $cust).Code -eq 403)
Check 'customer promotions list -> 403' ((Call GET '/api/promotions' $null $cust).Code -eq 403)
Check 'customer order management -> 403' ((Call GET '/api/orders/manage' $null $cust).Code -eq 403)
Check 'staff analytics -> 403' ((Call GET '/api/analytics/dashboard' $null $staff).Code -eq 403)
Check 'admin cart -> 403 (admins do not shop)' ((Call GET '/api/cart' $null $admin).Code -eq 403)
Check 'delivery order management -> 403' ((Call GET '/api/orders/manage' $null $dlv).Code -eq 403)
Check 'warehouse inventory read -> 200' ((Call GET '/api/inventory' $null $wh).Code -eq 200)
Check 'staff inventory read -> 200' ((Call GET '/api/inventory' $null $staff).Code -eq 200)
Check 'staff cannot adjust stock -> 403' ((Call PUT '/api/inventory/1' @{ newQuantity = 50; reason = 'x' } $staff).Code -eq 403)
Check 'customer cannot list delivery staff -> 403' ((Call GET '/api/users?role=DELIVERY' $null $cust).Code -eq 403)

Section 'FR-01 Products'
$list = Call GET '/api/products?size=50'
Check 'public product list has 24 products' ($list.Json.totalElements -eq 24) "got $($list.Json.totalElements)"
Check 'products carry a primary image path' (($list.Json.content | Where-Object { -not $_.primaryImage }).Count -eq 0)
$img = Invoke-WebRequest "$Base$($list.Json.content[0].primaryImage)" -SkipHttpErrorCheck
Check 'product image is served (200 image/jpeg)' ($img.StatusCode -eq 200 -and $img.Headers['Content-Type'] -match 'image')
$allImgOk = $true; foreach ($p in $list.Json.content) { if ((Invoke-WebRequest "$Base$($p.primaryImage)" -SkipHttpErrorCheck).StatusCode -ne 200) { $allImgOk = $false } }
Check 'all 24 product images load' $allImgOk
Check 'search q=headphones' ((Call GET '/api/products?q=headphones').Json.totalElements -ge 1)
Check 'filter by category' ((@((Call GET '/api/products?categoryId=2&size=50').Json.content | Where-Object { $_.category.id -ne 2 })).Count -eq 0)
Check 'filter by price range' ((@((Call GET '/api/products?minPrice=10000&maxPrice=20000&size=50').Json.content | Where-Object { $_.price -lt 10000 -or $_.price -gt 20000 })).Count -eq 0)
$desc = (Call GET '/api/products?sort=price_desc&size=5').Json.content
Check 'sort price high-low' ($desc[0].price -ge $desc[1].price)
Check 'pagination' ((Call GET '/api/products?size=5&page=1').Json.content.Count -eq 5)
Check 'product 404 for unknown id' ((Call GET '/api/products/99999').Code -eq 404)
$bad = Call POST '/api/products' @{ name = 'ab'; price = -5; sku = ''; categoryId = 1; brandId = 1 } $admin
Check 'create product validation -> 400 with field errors' ($bad.Code -eq 400 -and $bad.Json.fieldErrors.name)
Check 'duplicate SKU -> 409' ((Call POST '/api/products' @{ name = 'Duplicate'; price = 100; sku = 'TSH-001'; categoryId = 1; brandId = 1 } $admin).Code -eq 409)
$new = Call POST '/api/products' @{ name = 'Test Product'; description = 'Created by tests'; price = 999.5; sku = 'tst-9001'; categoryId = 1; brandId = 1; initialStock = 25; reorderLevel = 5 } $admin
Check 'admin creates product -> 201' ($new.Code -eq 201 -and $new.Json.sku -eq 'TST-9001' -and $new.Json.stock -eq 25)
$np = $new.Json.id
$up = Call PUT "/api/products/$np" @{ name = 'Test Product v2'; description = 'edited'; price = 1200; sku = 'TST-9001'; categoryId = 2; brandId = 2; status = 'ACTIVE' } $admin
Check 'admin updates product' ($up.Code -eq 200 -and $up.Json.name -eq 'Test Product v2' -and $up.Json.price -eq 1200)
# image upload (multipart)
$client = [System.Net.Http.HttpClient]::new(); $client.DefaultRequestHeaders.Authorization = [System.Net.Http.Headers.AuthenticationHeaderValue]::new('Bearer', $admin)
$mp = [System.Net.Http.MultipartFormDataContent]::new()
$bytes = [System.IO.File]::ReadAllBytes((Join-Path $PSScriptRoot '..\images\products\mug-coffee.jpg'))
$fc = [System.Net.Http.ByteArrayContent]::new($bytes); $fc.Headers.ContentType = [System.Net.Http.Headers.MediaTypeHeaderValue]::Parse('image/jpeg'); $mp.Add($fc, 'file', 'x.jpg')
$ur = $client.PostAsync("$Base/api/products/$np/image", $mp).Result
$upj = $ur.Content.ReadAsStringAsync().Result | ConvertFrom-Json
Check 'admin uploads product image -> 201' ([int]$ur.StatusCode -eq 201 -and $upj.imagePath -like '/images/products/upload-*')
Check 'uploaded image is served' ((Invoke-WebRequest "$Base$($upj.imagePath)" -SkipHttpErrorCheck).StatusCode -eq 200)
Check 'GET /products/{id}/images lists it' ((Call GET "/api/products/$np/images").Json.Count -eq 1)
$mp2 = [System.Net.Http.MultipartFormDataContent]::new(); $tc = [System.Net.Http.ByteArrayContent]::new([System.Text.Encoding]::UTF8.GetBytes('not an image')); $tc.Headers.ContentType = [System.Net.Http.Headers.MediaTypeHeaderValue]::Parse('image/jpeg'); $mp2.Add($tc, 'file', 'evil.jpg')
Check 'fake image (bad content) rejected -> 400' ([int]$client.PostAsync("$Base/api/products/$np/image", $mp2).Result.StatusCode -eq 400)
Check 'delete product image -> 204' ((Call DELETE "/api/products/$np/images/$($upj.id)" $null $admin).Code -eq 204)
Check 'customer cannot upload image -> 403' ((Call POST "/api/products/$np/image" $null $cust).Code -eq 403)
Check 'admin deletes product -> 204' ((Call DELETE "/api/products/$np" $null $admin).Code -eq 204)
Check 'deleted product is gone (404)' ((Call GET "/api/products/$np").Code -eq 404)
Check 'SKU can be reused after delete' ((Call POST '/api/products' @{ name = 'Reuse SKU'; price = 10; sku = 'TST-9001'; categoryId = 1; brandId = 1 } $admin).Code -eq 201)

Section 'FR-05 Promotions'
function Validate($code, $amt = 10000) { (Call POST '/api/promotions/validate' @{ couponCode = $code; orderAmount = $amt }).Json }
$v = Validate 'SUMMER10'; Check 'SUMMER10 valid: 10% off' ($v.isValid -and $v.discountAmount -eq 1000 -and $v.finalAmount -eq 9000)
$v = Validate 'lkr500off'; Check 'LKR500OFF valid (case-insensitive) fixed 500' ($v.isValid -and $v.discountAmount -eq 500)
$v = Validate 'FLASH25'; Check 'FLASH25 expired -> invalid' (-not $v.isValid -and $v.message -match 'expired')
$v = Validate 'MEGA30'; Check 'MEGA30 inactive -> invalid' (-not $v.isValid -and $v.message -match 'not active')
$v = Validate 'LIMITED5'; Check 'LIMITED5 usage limit reached -> invalid' (-not $v.isValid -and $v.message -match 'usage limit')
$v = Validate 'NOPE1234'; Check 'unknown code -> invalid' (-not $v.isValid -and $v.message -match 'not found')
$v = Validate 'LKR500OFF' 300; Check 'fixed discount capped at order amount' ($v.isValid -and $v.discountAmount -eq 300 -and $v.finalAmount -eq 0)
Check 'promotions list (admin)' ((Call GET '/api/promotions' $null $admin).Json.Count -ge 7)
$today = (Get-Date).ToString('yyyy-MM-dd'); $later = (Get-Date).AddDays(30).ToString('yyyy-MM-dd')
$pn = Call POST '/api/promotions' @{ couponCode = 'TEST15'; discountType = 'PERCENTAGE'; discountValue = 15; startDate = $today; endDate = $later; usageLimit = 2; active = $true } $admin
Check 'admin creates promotion -> 201' ($pn.Code -eq 201 -and $pn.Json.remainingUsage -eq 2)
Check 'duplicate coupon -> 409' ((Call POST '/api/promotions' @{ couponCode = 'test15'; discountType = 'FIXED'; discountValue = 5; startDate = $today; endDate = $later } $admin).Code -eq 409)
Check 'percentage > 100 -> 400' ((Call POST '/api/promotions' @{ couponCode = 'BIGPCT'; discountType = 'PERCENTAGE'; discountValue = 150; startDate = $today; endDate = $later } $admin).Code -eq 400)
Check 'start after end -> 400' ((Call POST '/api/promotions' @{ couponCode = 'BADDATE'; discountType = 'FIXED'; discountValue = 5; startDate = $later; endDate = $today } $admin).Code -eq 400)
Check 'short code -> 400' ((Call POST '/api/promotions' @{ couponCode = 'AB'; discountType = 'FIXED'; discountValue = 5; startDate = $today; endDate = $later } $admin).Code -eq 400)
$pid2 = $pn.Json.id
Check 'deactivate promotion' ((Call POST "/api/promotions/$pid2/deactivate" $null $admin).Json.isActive -eq $false)
Check 'deactivated coupon is rejected' (-not (Validate 'TEST15').isValid)
Check 'activate promotion' ((Call POST "/api/promotions/$pid2/activate" $null $admin).Json.isActive -eq $true)
$upd = Call PUT "/api/promotions/$pid2" @{ couponCode = 'TEST15'; discountType = 'FIXED'; discountValue = 250; startDate = $today; endDate = $later; usageLimit = 5 } $admin
Check 'update promotion' ($upd.Json.discountType -eq 'FIXED' -and $upd.Json.discountValue -eq 250)
Check 'delete promotion -> 204' ((Call DELETE "/api/promotions/$pid2" $null $admin).Code -eq 204)
Check 'deleted coupon no longer validates' (-not (Validate 'TEST15').isValid)

Section 'FR-02 Cart'
Call DELETE '/api/cart' $null $cust | Out-Null
$c = Call POST '/api/cart/items' @{ productId = 7; quantity = 2 } $cust
Check 'add to cart -> 201, subtotal = 2 x 1850' ($c.Code -eq 201 -and $c.Json.subtotal -eq 3700 -and $c.Json.itemCount -eq 2)
$c = Call POST '/api/cart/items' @{ productId = 7; quantity = 1 } $cust
Check 'adding same product merges quantity' ($c.Json.items.Count -eq 1 -and $c.Json.items[0].quantity -eq 3)
Check 'add out-of-stock product -> 409' ((Call POST '/api/cart/items' @{ productId = 12; quantity = 1 } $cust).Code -eq 409)
Check 'add more than stock -> 409' ((Call POST '/api/cart/items' @{ productId = 23; quantity = 4 } $cust).Code -eq 409)
Check 'quantity 0 -> 400' ((Call POST '/api/cart/items' @{ productId = 7; quantity = 0 } $cust).Code -eq 400)
Check 'unknown product -> 404' ((Call POST '/api/cart/items' @{ productId = 9999; quantity = 1 } $cust).Code -eq 404)
$itemId = $c.Json.items[0].id
Call POST '/api/cart/items' @{ productId = 23; quantity = 1 } $cust | Out-Null
$lowItem = ((Call GET '/api/cart' $null $cust).Json.items | Where-Object { $_.productId -eq 23 }).id
$u = Call PUT "/api/cart/items/$itemId" @{ quantity = 5 } $cust
Check 'update cart quantity' ($u.Json.items[0].quantity -eq 5 -and $u.Json.subtotal -eq 16450)
Check 'update beyond stock -> 409' ((Call PUT "/api/cart/items/$lowItem" @{ quantity = 50 } $cust).Code -eq 409)
$pv = Call GET '/api/cart?couponCode=SUMMER10' $null $cust
Check 'cart coupon preview computes discount' ($pv.Json.discountApplied -eq 1645 -and $pv.Json.couponCode -eq 'SUMMER10')
Check 'cart preview of expired coupon is flagged' ((Call GET '/api/cart?couponCode=FLASH25' $null $cust).Json.couponValid -eq $false)
Check 'other user cannot touch my cart item' ((Call DELETE "/api/cart/items/$itemId" $null $cust2).Code -eq 404)
$rm = Call DELETE "/api/cart/items/$itemId" $null $cust
Check 'remove from cart' ($rm.Json.items.Count -eq 1)
Call DELETE '/api/cart' $null $cust | Out-Null

Section 'FR-02/03/04 Checkout, mock payment, stock, promotions'
Check 'checkout with empty cart -> 400' ((Checkout $cust).Code -eq 400)
Call POST '/api/cart/items' @{ productId = 2; quantity = 1 } $cust | Out-Null
Call POST '/api/cart/items' @{ productId = 7; quantity = 2 } $cust | Out-Null
$s2 = Stock 2 $admin; $s7 = Stock 7 $admin
$w1 = Call POST '/api/checkout' @{ email = 'bad'; firstName = ''; lastName = 'P'; address = ''; city = ''; postalCode = ''; country = 'Sri Lanka'; phone = '12'; payment = (Card) } $cust
Check 'checkout field validation -> 400 with field errors' ($w1.Code -eq 400 -and $w1.Json.fieldErrors.email -and $w1.Json.fieldErrors.phone)
$d = Checkout $cust $null (Card '4000000000000002')
Check 'declined test card -> 402' ($d.Code -eq 402)
Check 'unknown card number -> 402' ((Checkout $cust $null (Card '4242424242424242')).Code -eq 402)
Check 'invalid card (Luhn) -> 402' ((Checkout $cust $null (Card '1234567890123456')).Code -eq 402)
Check 'failed payments leave stock untouched' ((Stock 2 $admin) -eq $s2 -and (Stock 7 $admin) -eq $s7)
Check 'failed payments keep the cart' ((Call GET '/api/cart' $null $cust).Json.items.Count -eq 2)
Check 'expired coupon at checkout -> 400 and nothing saved' ((Checkout $cust 'FLASH25').Code -eq 400 -and (Stock 2 $admin) -eq $s2)
$wu = (Call GET '/api/promotions' $null $admin).Json | Where-Object { $_.couponCode -eq 'WELCOME15' }
$ck = Checkout $cust 'WELCOME15'
Check 'checkout with WELCOME15 + Visa test card -> 201' ($ck.Code -eq 201) $ck.Raw
Check 'server computed totals (22600 - 15% = 19210)' ($ck.Json.subtotal -eq 22600 -and $ck.Json.discountApplied -eq 3390 -and $ck.Json.totalAmount -eq 19210)
Check 'order number + estimated delivery returned' ($ck.Json.orderNumber -match '^SS-\d{8}-\d{5}$' -and $ck.Json.estimatedDelivery)
Check 'card details never echoed (only last4)' ($ck.Json.cardLast4 -eq '1111' -and $ck.Raw -notmatch '4111111111111111')
Check 'inventory decreased (headphones -1, mug -2)' ((Stock 2 $admin) -eq $s2 - 1 -and (Stock 7 $admin) -eq $s7 - 2)
$mv = (Call GET '/api/inventory/2/movements' $null $admin).Json.content[0]
Check 'stock movement recorded (OUT, -1, ORDER_PLACED)' ($mv.movementType -eq 'OUT' -and $mv.quantity -eq -1 -and $mv.reason -like 'ORDER_PLACED*' -and $mv.quantityAfter -eq ($s2 - 1))
Check 'cart cleared after checkout' ((Call GET '/api/cart' $null $cust).Json.items.Count -eq 0)
$wu2 = (Call GET '/api/promotions' $null $admin).Json | Where-Object { $_.couponCode -eq 'WELCOME15' }
Check 'promotion usage count incremented' ($wu2.usageCount -eq $wu.usageCount + 1)
$orderId = $ck.Json.orderId
$od = Call GET "/api/orders/$orderId" $null $cust
Check 'order detail: CONFIRMED + shipment + payment' ($od.Json.order.status -eq 'CONFIRMED' -and $od.Json.shipment.trackingNumber -and $od.Json.payment.status -eq 'SUCCESS' -and $od.Json.payment.cardLast4 -eq '1111')
Check 'order item snapshot price' ($od.Json.order.items.Count -eq 2 -and ($od.Json.order.items | Where-Object { $_.productId -eq 2 }).priceAtOrder -eq 18900)
Check 'My Orders lists the new order first' ((Call GET '/api/orders' $null $cust).Json.content[0].id -eq $orderId)
Check 'other customer cannot view my order -> 403' ((Call GET "/api/orders/$orderId" $null $cust2).Code -eq 403)
# stock can never go negative
Call POST '/api/cart/items' @{ productId = 23; quantity = 3 } $cust | Out-Null
Call PUT '/api/inventory/23' @{ newQuantity = 1; reason = 'test: shrink stock under the cart' } $admin | Out-Null
$neg = Checkout $cust
Check 'checkout with insufficient stock -> 409 (no negative stock)' ($neg.Code -eq 409 -and (Stock 23 $admin) -eq 1)
Check 'adjust to negative quantity -> 400' ((Call PUT '/api/inventory/23' @{ newQuantity = -5; reason = 'x' } $admin).Code -eq 400)
Call DELETE '/api/cart' $null $cust | Out-Null
Call PUT '/api/inventory/23' @{ newQuantity = 3; reason = 'test: restore' } $admin | Out-Null

Section 'FR-03 Order status flow & delivery'
Call POST '/api/cart/items' @{ productId = 7; quantity = 1 } $cust | Out-Null
$ck2 = Checkout $cust; $o2 = $ck2.Json.orderId; $s7b = Stock 7 $admin
Check 'second order placed' ($ck2.Code -eq 201)
$cn = Call DELETE "/api/orders/$o2" $null $cust
Check 'customer cancels own CONFIRMED order' ($cn.Code -eq 200 -and $cn.Json.order.status -eq 'CANCELLED')
Check 'cancel restores stock (ORDER_CANCELLED movement)' ((Stock 7 $admin) -eq $s7b + 1 -and (Call GET '/api/inventory/7/movements' $null $admin).Json.content[0].reason -like 'ORDER_CANCELLED*')
Check 'cancelled order cannot be cancelled again -> 409' ((Call DELETE "/api/orders/$o2" $null $cust).Code -eq 409)
Check 'customer cannot cancel another users order -> 403' ((Call DELETE "/api/orders/$orderId" $null $cust2).Code -eq 403)
Check 'customer cannot change order status -> 403' ((Call PUT "/api/orders/$orderId" @{ newStatus = 'PROCESSING' } $cust).Code -eq 403)
Check 'skipping steps is rejected (CONFIRMED -> DELIVERED) -> 409' ((Call PUT "/api/orders/$orderId" @{ newStatus = 'DELIVERED' } $staff).Code -eq 409)
Check 'unknown status -> 400' ((Call PUT "/api/orders/$orderId" @{ newStatus = 'BOGUS' } $staff).Code -eq 400)
Check 'staff CONFIRMED -> PROCESSING' ((Call PUT "/api/orders/$orderId" @{ newStatus = 'PROCESSING' } $staff).Json.order.status -eq 'PROCESSING')
Check 'warehouse cannot dispatch -> 403' ((Call PUT "/api/orders/$orderId" @{ newStatus = 'DISPATCHED' } $wh).Code -eq 403)
Check 'warehouse PROCESSING -> READY_FOR_DISPATCH' ((Call PUT "/api/orders/$orderId" @{ newStatus = 'READY_FOR_DISPATCH' } $wh).Json.order.status -eq 'READY_FOR_DISPATCH')
Check 'admin READY -> DISPATCHED (shipment follows)' ((Call PUT "/api/orders/$orderId" @{ newStatus = 'DISPATCHED' } $admin).Json.shipment.status -eq 'DISPATCHED')
$ship = (Call GET "/api/orders/$orderId/shipment" $null $cust).Json
Check 'customer sees shipment tracking' ($ship.trackingNumber -and $ship.status -eq 'DISPATCHED')
Check 'shipment list (staff)' ((Call GET '/api/shipments?size=50' $null $staff).Json.totalElements -ge 8)
Check 'delivery users list' ((Call GET '/api/users?role=DELIVERY' $null $staff).Json.Count -eq 2)
Check 'delivery person cannot see unassigned order -> 403' ((Call GET "/api/orders/$orderId" $null $dlv).Code -eq 403)
Check 'delivery cannot update unassigned shipment -> 403' ((Call PUT "/api/shipments/$($ship.id)" @{ status = 'OUT_FOR_DELIVERY' } $dlv).Code -eq 403)
Check 'delivery cannot assign deliveries -> 403' ((Call POST '/api/deliveries/assign' @{ shipmentId = $ship.id; staffId = 4 } $dlv).Code -eq 403)
Check 'assigning a non-delivery user -> 400' ((Call POST '/api/deliveries/assign' @{ shipmentId = $ship.id; staffId = 5 } $staff).Code -eq 400)
$as = Call POST '/api/deliveries/assign' @{ shipmentId = $ship.id; staffId = 4 } $staff
Check 'staff assigns delivery to Suresh' ($as.Code -eq 200 -and $as.Json.delivery.staffId -eq 4 -and $as.Json.delivery.status -eq 'ASSIGNED')
$mine = (Call GET '/api/deliveries/mine' $null $dlv).Json
Check 'delivery person sees the assignment' (($mine | Where-Object { $_.orderId -eq $orderId }).Count -eq 1)
Check 'delivery person can view assigned order' ((Call GET "/api/orders/$orderId" $null $dlv).Code -eq 200)
Check 'cannot mark delivered before starting -> 409' ((Call PUT "/api/deliveries/$($as.Json.delivery.id)/status" @{ status = 'COMPLETED' } $dlv).Code -eq 409)
$st = Call PUT "/api/deliveries/$($as.Json.delivery.id)/status" @{ status = 'IN_PROGRESS' } $dlv
Check 'delivery starts -> order OUT_FOR_DELIVERY' ($st.Json.orderStatus -eq 'OUT_FOR_DELIVERY' -and $st.Json.delivery.status -eq 'IN_PROGRESS')
Check 'other delivery user cannot update it -> 403' ((Call PUT "/api/deliveries/$($as.Json.delivery.id)/status" @{ status = 'COMPLETED' } (Login 'delivery2@shopsphere.lk')).Code -eq 403)
Check 'customer cannot cancel once out for delivery -> 409' ((Call DELETE "/api/orders/$orderId" $null $cust).Code -eq 409)
$done = Call PUT "/api/deliveries/$($as.Json.delivery.id)/status" @{ status = 'COMPLETED' } $dlv
Check 'delivery completed -> order DELIVERED' ($done.Json.orderStatus -eq 'DELIVERED' -and $done.Json.status -eq 'DELIVERED')
Check 'delivered order cannot be cancelled by admin -> 409' ((Call DELETE "/api/orders/$orderId" $null $admin).Code -eq 409)
$mg = Call GET '/api/orders/manage?status=DELIVERED&size=50' $null $admin
Check 'order management filter by status' ($mg.Json.totalElements -ge 6 -and ($mg.Json.content | Where-Object { $_.status -ne 'DELIVERED' }).Count -eq 0)
Check 'order management search by customer' ((Call GET '/api/orders/manage?q=kavindi' $null $staff).Json.totalElements -ge 1)
Check 'PENDING seed order can be confirmed (creates shipment)' ((Call PUT '/api/orders/12' @{ newStatus = 'CONFIRMED' } $admin).Json.shipment.trackingNumber -ne $null)

Section 'FR-04 Inventory'
$inv = (Call GET '/api/inventory?size=50' $null $wh).Json
Check 'inventory list has every product' ($inv.totalElements -ge 24)
Check 'low-stock endpoint returns items below reorder level' ((Call GET '/api/inventory/low-stock' $null $wh).Json.Count -ge 4)
Check 'lowStockOnly filter' ((@((Call GET '/api/inventory?lowStockOnly=true' $null $admin).Json.content | Where-Object { -not $_.isLowStock })).Count -eq 0)
$ad = Call PUT '/api/inventory/8' @{ newQuantity = 150; reason = 'Cycle count' } $wh
Check 'warehouse adjusts stock (ADJUSTMENT movement)' ($ad.Json.quantity -eq 150 -and (Call GET '/api/inventory/8/movements' $null $wh).Json.content[0].movementType -eq 'ADJUSTMENT')
$rs = Call POST '/api/inventory/8/restock' @{ quantity = 20; reason = 'PO-9001' } $admin
Check 'restock adds stock (IN movement)' ($rs.Json.quantity -eq 170)
Check 'adjust without reason -> 400' ((Call PUT '/api/inventory/8' @{ newQuantity = 10; reason = '' } $admin).Code -eq 400)

Section 'FR-06 Analytics & reports (from real data)'
$dash = (Call GET '/api/analytics/dashboard' $null $admin).Json
Check 'dashboard totals come from the DB' ($dash.totalRevenue -gt 0 -and $dash.orderCount -ge 14 -and $dash.averageOrderValue -gt 0)
Check 'top products / categories / trend present' ($dash.topProducts.Count -ge 5 -and $dash.salesByCategory.Count -ge 3 -and $dash.salesByDate.Count -ge 5)
$sum = 0; $dash.orderStatusSummary.PSObject.Properties | ForEach-Object { $sum += $_.Value }
Check 'status summary adds up to order count' ($sum -eq $dash.orderCount)
Check 'low-stock products listed' ($dash.lowStockProducts.Count -ge 1)
Check 'top products ordered by units' ($dash.topProducts[0].unitsSold -ge $dash.topProducts[1].unitsSold)
$sales = (Call GET '/api/analytics/sales?categoryId=2' $null $admin).Json
Check 'sales data filter by category' ($sales.rows.Count -ge 1 -and ($sales.rows | Where-Object { $_.category -ne 'Electronics' }).Count -eq 0)
Check 'top-products endpoint' ((Call GET '/api/analytics/top-products?limit=3' $null $admin).Json.Count -eq 3)
$rep = Call POST '/api/reports' @{ reportName = 'Test report'; reportType = 'PRODUCT_PERFORMANCE'; startDate = (Get-Date).AddDays(-90).ToString('yyyy-MM-dd'); endDate = $today; exportFormat = 'CSV' } $admin
Check 'create saved report -> 201' ($rep.Code -eq 201)
Check 'report validation -> 400' ((Call POST '/api/reports' @{ reportName = ''; reportType = 'X'; startDate = $today; endDate = $today; exportFormat = 'PDF' } $admin).Code -eq 400)
$rd = Call GET "/api/reports/$($rep.Json.id)" $null $admin
Check 'view report generates data' ($rd.Json.data.rows.Count -ge 1 -and $rd.Json.data.columns[0] -eq 'Product')
$rup = Call PUT "/api/reports/$($rep.Json.id)" @{ reportName = 'Renamed'; reportType = 'CATEGORY_PERFORMANCE'; startDate = (Get-Date).AddDays(-90).ToString('yyyy-MM-dd'); endDate = $today; exportFormat = 'JSON' } $admin
Check 'update saved report' ($rup.Json.reportName -eq 'Renamed' -and $rup.Json.reportType -eq 'CATEGORY_PERFORMANCE')
$ex = Call GET "/api/reports/$($rep.Json.id)/export" $null $admin
Check 'CSV export' ($ex.Code -eq 200 -and $ex.Raw -match 'Category')
Check 'reports list' ((Call GET '/api/reports' $null $admin).Json.Count -ge 3)
Check 'delete report -> 204' ((Call DELETE "/api/reports/$($rep.Json.id)" $null $admin).Code -eq 204)
Check 'deleted report -> 404' ((Call GET "/api/reports/$($rep.Json.id)" $null $admin).Code -eq 404)

Section 'Registration & profile'
$email = "test$([guid]::NewGuid().ToString('N').Substring(0,8))@example.com"
$rg = Call POST '/api/auth/register' @{ email = $email; password = 'Passw0rd1'; firstName = 'Tess'; lastName = 'Ter'; phone = '0712345678' }
Check 'register -> 201 as CUSTOMER' ($rg.Code -eq 201 -and $rg.Json.user.role -eq 'CUSTOMER')
Check 'duplicate email -> 409' ((Call POST '/api/auth/register' @{ email = $email; password = 'Passw0rd1'; firstName = 'T'; lastName = 'T' }).Code -eq 409)
Check 'weak password -> 400' ((Call POST '/api/auth/register' @{ email = 'x@y.lk'; password = 'short'; firstName = 'T'; lastName = 'T' }).Code -eq 400)
$nt = $rg.Json.accessToken
Check 'new user can log in' ((Call POST '/api/auth/login' @{ email = $email; password = 'Passw0rd1' }).Code -eq 200)
Check 'update profile' ((Call PUT '/api/users/me' @{ firstName = 'Tessa'; lastName = 'Ter'; phone = '0712345678' } $nt).Json.firstName -eq 'Tessa')
Check 'wrong current password -> 400' ((Call PUT '/api/users/me/password' @{ currentPassword = 'bad'; newPassword = 'Another1x' } $nt).Code -eq 400)
Check 'change password -> 204' ((Call PUT '/api/users/me/password' @{ currentPassword = 'Passw0rd1'; newPassword = 'Another1x' } $nt).Code -eq 204)
Check 'login with new password' ((Call POST '/api/auth/login' @{ email = $email; password = 'Another1x' }).Code -eq 200)
$a1 = Call POST '/api/users/me/addresses' @{ label = 'Home'; address = '1 Test St'; city = 'Colombo'; postalCode = '00100'; country = 'Sri Lanka'; phone = '0712345678'; defaultAddress = $false } $nt
Check 'first address becomes default' ($a1.Code -eq 201 -and $a1.Json.defaultAddress -eq $true)
$a2 = Call POST '/api/users/me/addresses' @{ label = 'Work'; address = '2 Test St'; city = 'Kandy'; postalCode = '20000'; country = 'Sri Lanka'; defaultAddress = $true } $nt
$addrs = (Call GET '/api/users/me/addresses' $null $nt).Json
Check 'setting a new default unsets the old one' ($addrs.Count -eq 2 -and ($addrs | Where-Object { $_.defaultAddress }).Count -eq 1 -and ($addrs | Where-Object { $_.defaultAddress }).label -eq 'Work')
Check 'edit address' ((Call PUT "/api/users/me/addresses/$($a1.Json.id)" @{ label = 'Home2'; address = '1 Test St'; city = 'Colombo'; postalCode = '00100'; country = 'Sri Lanka'; defaultAddress = $false } $nt).Json.label -eq 'Home2')
Check "cannot edit someone else's address -> 404" ((Call PUT "/api/users/me/addresses/1" @{ label = 'Hack'; address = 'x'; city = 'x'; postalCode = 'x'; country = 'x'; defaultAddress = $false } $nt).Code -eq 404)
Check 'delete address -> 204' ((Call DELETE "/api/users/me/addresses/$($a1.Json.id)" $null $nt).Code -eq 204)

Write-Host ("`nRESULT: {0} passed, {1} failed" -f $script:pass, $script:fail) -ForegroundColor $(if ($script:fail) { 'Red' } else { 'Green' })
exit $(if ($script:fail) { 1 } else { 0 })
