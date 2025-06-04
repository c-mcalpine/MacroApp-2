# Macro App API

Serverless API for the Macro App, built with Next.js and deployed on Vercel.

## API Endpoints

### Authentication

#### Send OTP
```http
POST /api/auth/send-otp
Content-Type: application/json

{
  "phone_number": "+1234567890"
}
```

#### Verify OTP
```http
POST /api/auth/verify-otp
Content-Type: application/json

{
  "phone_number": "+1234567890",
  "otp_code": "123456",
  "username": "optional_username"
}
```

#### Update Username
```http
POST /api/auth/update-username
Content-Type: application/json
Authorization: Bearer <token>

{
  "phone_number": "+1234567890",
  "username": "new_username"
}
```

### Recipes

#### Get All Recipes
```http
GET /api/recipes
```

#### Get Recipe by ID
```http
GET /api/recipe/[id]
```

#### Chat with Recipe
```http
POST /api/recipe/chat
Content-Type: application/json
Authorization: Bearer <token>

{
  "recipe_id": "123",
  "message": "How do I make this healthier?"
}
```

#### Search Recipes
```http
GET /api/search?q=chicken&min_protein=20
```

#### Filter Recipes by Calories per Gram of Protein
```http
GET /api/recipes/filter
```

### Shopping List

#### Generate Instacart List
```http
POST /api/instacart/shopping-list
Content-Type: application/json
Authorization: Bearer <token>

{
  "ingredients": ["chicken", "rice", "broccoli"]
}
```

## Rate Limits

- Auth endpoints: 5 requests per minute
- Chat endpoints: 10 requests per minute
- Search endpoints: 30 requests per minute
- Other endpoints: 20 requests per minute

## Environment Variables

```env
# Supabase
SUPABASE_URL=
SUPABASE_ANON_KEY=

# Twilio
TWILIO_ACCOUNT_SID=
TWILIO_AUTH_TOKEN=
TWILIO_VERIFY_SERVICE_SID=

# OpenAI
OPENAI_API_KEY=

# JWT
JWT_SECRET=

# Instacart
INSTACART_API_KEY=

# Upstash Redis
UPSTASH_REDIS_REST_URL=
UPSTASH_REDIS_REST_TOKEN=
```

## Development

```bash
npm install
npm run dev
```

## Deployment

The API is automatically deployed to Vercel when changes are pushed to the main branch. 