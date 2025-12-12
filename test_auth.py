import http.client
import json

# 设置测试参数
import random
import string

# 生成随机邮箱地址，避免重复
random_str = ''.join(random.choices(string.ascii_lowercase + string.digits, k=8))
EMAIL = f"test_user_{random_str}@example.com"
PASSWORD = "test_password_123"
NAME = "Test User"

# 创建HTTP连接
conn = http.client.HTTPConnection("localhost", 10000)

print("=== 开始测试完整认证流程 ===\n")

# 1. 测试注册
print("1. 测试用户注册...")
register_data = {
    "email": EMAIL,
    "password": PASSWORD,
    "name": NAME
}
register_body = json.dumps(register_data)

conn.request("POST", "/api/v1/auth/register", register_body, {"Content-Type": "application/json"})
register_response = conn.getresponse()
register_status = register_response.status
register_data = json.loads(register_response.read().decode())
print(f"注册状态码: {register_status}")
print(f"注册响应: {register_data}")

if register_status != 200:
    print("注册失败，测试结束")
    conn.close()
    exit(1)

print("✓ 注册成功\n")

# 2. 测试登录
print("2. 测试用户登录...")
login_data = {
    "email": EMAIL,
    "password": PASSWORD
}
login_body = json.dumps(login_data)

conn.request("POST", "/api/v1/auth/login", login_body, {"Content-Type": "application/json"})
login_response = conn.getresponse()
login_status = login_response.status
login_data = json.loads(login_response.read().decode())
print(f"登录状态码: {login_status}")
print(f"登录响应: {login_data}")

if login_status != 200:
    print("登录失败，测试结束")
    conn.close()
    exit(1)

access_token = login_data.get("accessToken")
if not access_token:
    print("登录响应中没有accessToken，测试结束")
    conn.close()
    exit(1)

print("✓ 登录成功\n")

# 3. 测试auth/me接口
print("3. 测试/auth/me接口...")
auth_headers = {
    "Content-Type": "application/json",
    "Authorization": f"Bearer {access_token}"
}

conn.request("GET", "/api/v1/auth/me", headers=auth_headers)
me_response = conn.getresponse()
me_status = me_response.status
me_data = json.loads(me_response.read().decode())
print(f"auth/me状态码: {me_status}")
print(f"auth/me响应: {me_data}")

if me_status != 200:
    print("auth/me失败，测试结束")
    conn.close()
    exit(1)

# 验证返回的用户信息
if me_data.get("email") != EMAIL or me_data.get("name") != NAME:
    print(f"auth/me返回的用户信息不正确: {me_data}")
    conn.close()
    exit(1)

print("✓ auth/me接口返回正确用户信息\n")

# 4. 测试accounts/profile接口
print("4. 测试/accounts/profile接口...")

conn.request("GET", "/api/v1/accounts/profile", headers=auth_headers)
profile_response = conn.getresponse()
profile_status = profile_response.status
profile_data = json.loads(profile_response.read().decode())
print(f"accounts/profile状态码: {profile_status}")
print(f"accounts/profile响应: {profile_data}")

if profile_status != 200:
    print("accounts/profile失败，测试结束")
    conn.close()
    exit(1)

# 验证返回的用户信息
if profile_data.get("email") != EMAIL or profile_data.get("name") != NAME:
    print(f"accounts/profile返回的用户信息不正确: {profile_data}")
    conn.close()
    exit(1)

print("✓ accounts/profile接口返回正确用户信息\n")

# 5. 测试更新profile
print("5. 测试更新profile...")
new_name = "Updated Test User"
update_data = {
    "name": new_name
}
update_body = json.dumps(update_data)

conn.request("PATCH", "/api/v1/accounts/profile", update_body, auth_headers)
update_response = conn.getresponse()
update_status = update_response.status
update_data = json.loads(update_response.read().decode())
print(f"更新profile状态码: {update_status}")
print(f"更新profile响应: {update_data}")

if update_status != 200:
    print("更新profile失败，测试结束")
    conn.close()
    exit(1)

# 验证更新后的用户信息
if update_data.get("name") != new_name:
    print(f"更新profile返回的用户信息不正确: {update_data}")
    conn.close()
    exit(1)

print("✓ 更新profile成功\n")

# 6. 再次测试auth/me接口，验证更新是否生效
print("6. 再次测试auth/me接口，验证更新是否生效...")

conn.request("GET", "/api/v1/auth/me", headers=auth_headers)
me_response = conn.getresponse()
me_status = me_response.status
me_data = json.loads(me_response.read().decode())
print(f"auth/me状态码: {me_status}")
print(f"auth/me响应: {me_data}")

if me_status != 200:
    print("auth/me失败，测试结束")
    conn.close()
    exit(1)

# 验证返回的用户信息是否已更新
if me_data.get("name") != new_name:
    print(f"auth/me返回的用户信息未更新: {me_data}")
    conn.close()
    exit(1)

print("✓ auth/me接口返回已更新的用户信息\n")

# 7. 再次测试accounts/profile接口，验证更新是否生效
print("7. 再次测试accounts/profile接口，验证更新是否生效...")

conn.request("GET", "/api/v1/accounts/profile", headers=auth_headers)
profile_response = conn.getresponse()
profile_status = profile_response.status
profile_data = json.loads(profile_response.read().decode())
print(f"accounts/profile状态码: {profile_status}")
print(f"accounts/profile响应: {profile_data}")

if profile_status != 200:
    print("accounts/profile失败，测试结束")
    conn.close()
    exit(1)

# 验证返回的用户信息是否已更新
if profile_data.get("name") != new_name:
    print(f"accounts/profile返回的用户信息未更新: {profile_data}")
    conn.close()
    exit(1)

print("✓ accounts/profile接口返回已更新的用户信息\n")

# 关闭连接
conn.close()

print("=== 所有测试通过！认证流程完整正常 ===")
print("\n总结:")
print(f"1. 注册用户: {EMAIL}")
print(f"2. 登录成功，获取到token")
print(f"3. auth/me接口返回正确用户信息")
print(f"4. accounts/profile接口返回正确用户信息")
print(f"5. 成功更新用户昵称: {NAME} -> {new_name}")
print(f"6. 更新后，auth/me和accounts/profile接口都返回更新后的信息")
