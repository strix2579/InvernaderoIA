import requests

def test_login():
    url = "http://localhost:8080/auth/login"
    payload = {
        "username": "strix__",
        "password": "Junior2579"
    }
    headers = {
        "Content-Type": "application/x-www-form-urlencoded"
    }
    
    try:
        response = requests.post(url, data=payload, headers=headers)
        print(f"Status Code: {response.status_code}")
        print(f"Response: {response.text}")
        
        if response.status_code == 200:
            print("✅ Login exitoso en el backend")
        else:
            print("❌ Login fallido en el backend")
            
    except Exception as e:
        print(f"❌ Error conectando al backend: {e}")

if __name__ == "__main__":
    test_login()
