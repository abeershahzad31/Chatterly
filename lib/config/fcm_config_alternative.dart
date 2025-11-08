// Alternative approach using complete service account JSON
class FCMConfigAlternative {
  // Complete service account JSON - replace with your actual JSON
  static const Map<String, dynamic> serviceAccountJson = {
    "type": "service_account",
    "project_id": "chatterly-9b2d2",
    "private_key_id": "your-private-key-id",
    "private_key": '''-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDofoaiDj7K9CMN\n+2OWNcRawaSllGUAvtU51AccpmRGQT4DOaqKBDaOyb7aqlrmfI8op0AoCNxIevUK\nmu4kbVResXKDNptNGFYUWVW1WodWWSGpnpLdhEEqcvKMQ79hR+lTAAiZTkWas2JC\nFEauctDwXWbV6w0oVtU10YhzBvwb9euKeZtyAlwY5efW6QApeAwK2AaO0hJ33Ixn\nNCYe2F0JW8umBTprH1X5QDPgKfFK/04UNJmX/DCXfLIU9vZlmh07ENMOPFUjk0Fg\nQWgPFCk38f6rE+plKLQ2qLHFV3vf76C0XKKfxdzvCIWwu1jdqEo3p8skS1LMHoPR\nrWT8s3VxAgMBAAECggEADWGrgWMK8ObL8W9vDUy9px4u3Hku/1hX8MB+53BQkjHA\nsuj3kRUO2ovLGrva9fVSYO5G4LApS+uIYhFhfWutzGkvyQt0WdqwhITjgzWZV4yc\nfJwC2P+NOhKaER1l+rvryND6wAHfFnAo3P84MWPRGdNy/LoF433+0SeuBuzcNSrQ\nyE4zMLtA55aliZAuYo+oufAJ9lheb2C5ud1MM6TWUVjWfbH7rdkU9cQ5FBlY9loB\nXSO/AmyG1FdpevpGi4L25VYAAFQvR8SUZWQhuMVxs0A446sMB5AOWmTzQv8sbKxw\nl4N4Wqaw19bKMZLGikAnqLAJ2HBR0cnRUDVm3EKfZwKBgQD7vOL+4utSGlFRSLMQ\ne5HRB+Q3i7kxou8KhC71i4tL0ulSWP+CONy3SPQWiUe1O8twBxaa42ZshdlCkhde\n7DbdHN9h5mJOiFRTQbho/GbwSq/oZvVcDx90y2sl4OGaQ9qfyRWNcivv+yxmbJJr\nG9itR0osEG6MYHCrrjjlbLbXOwKBgQDsbjsx16dPh8GIKv+LT7xE4TCYanrocLwz\nGzK73fx8ueGARQGN4McSKRVt0pYhxEeGSgGIrrZJQy39KZYeefz4nS4FWvjeb+Xa\nXfcBnqV5EAfkGar6sDdV1T9w5QH/ngy5pGpM3VmfLfgrIMikRkUMgj9YdB7wEvZk\nbY5rPCNTQwKBgAWdoxq4iTNdru63RndZqlkVafvrPAhlcBu18y47HLJmVBooLhsD\nlbjpAbj2+wiJ+vHW1qRB6mkFW2FmzOqrLlYkbL9MWmkSFX99+dUtvEYkBGSU12hk\nVflPCGbh62Z7mQbzf22WXHCQE999EI8fIehLrNXqz+yFwj2yN0a29CU9AoGBAMSy\nVGb8DgLZY4Ygl6dT98KqQl6bP5O/rqMp/oRTg2pUzqmDP27E0XlnWp+acjK3c/Xh\n/fKzv42l6U3UWkMSpAZF5fKoo6GTIHwSbpwXW30jfB0lyZx0HCU5m2UV8RqzZ8zO\nX22BPb1zZiKjTKl2mJ12grLZMJ/0dq5IgxLt3km3AoGACsB0C/LjGPW8Vktd7+N8\n8TRQ8EDDTSml7K30+ikQLgmbAIOAb4l/690UBTYRoj3pVKotzE5nxVNP1Gf5RXUc\nT5zAPGsHfEf2Q4i/XKTxXexJ6Z0SCmPVpHpwzYSGjUT3xw3xNQiYVOtLrnQfS5gT\nMqKyZoawQqrTbUByOY1umJw=\n-----END PRIVATE KEY-----\n''',
    "client_email": "firebase-adminsdk-fbsvc@chatterly-9b2d2.iam.gserviceaccount.com",
    "client_id": "YOUR_CLIENT_ID_HERE", // Replace with actual client_id
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40chatterly-9b2d2.iam.gserviceaccount.com"
  };

  static String get projectId => serviceAccountJson['project_id'] as String;
  static String get clientEmail => serviceAccountJson['client_email'] as String;
  static String get privateKey => serviceAccountJson['private_key'] as String;
  static String get clientId => serviceAccountJson['client_id'] as String;

  // Helper method to check if credentials are configured
  static bool get isConfigured => 
      clientId != 'YOUR_CLIENT_ID_HERE' &&
      projectId != 'your-project-id';
}
