// Handle Login
document.getElementById('login-form').addEventListener('submit', function(e) {
    e.preventDefault();
    const userId = document.getElementById('loginUserId').value;
    const password = document.getElementById('loginPassword').value;

    fetch('http://localhost:3000/admin/login', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ userId, password }),
    })
    .then(response => {
        if (!response.ok) {
            throw new Error('Login failed');
        }
        return response.json();
    })
    .then(data => {
        localStorage.setItem('token', data.token);
        window.location.href = 'index.html';  // Redirect to the main panel
    })
    .catch(error => {
        const messageDiv = document.getElementById('login-message');
        messageDiv.textContent = error.message;
    });
});

// Continue with previous code for users, channels, vod, series, and episodes
// ...

// Update fetch requests to include the token
const token = localStorage.getItem('token');
fetch('http://localhost:3000/api/users', {
    method: 'GET',
    headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
    },
})
.then(response => response.json())
.then(data => {
    // Handle the data as needed
})
.catch(error => console.error('Error:', error));

// Repeat for channels, vod, series, and episodes
