# Rails 8 API-only Application

This is a Ruby on Rails API-only application using PostgreSQL and designed for modern back-end services. It includes support for background jobs, service objects, transactional operations, and testing with RSpec.

## 🔧 Tech Stack

- **Ruby**: `3.3.x` (or specify your Ruby version here)
- **Rails**: `8.0.2`
- **Database**: PostgreSQL (`pg`)
- **Testing**: RSpec, FactoryBot, Faker
- **Environment**: `.env` via `dotenv-rails`
- **Code Quality**: Rubocop Rails Omakase

---

## 🛠️ Setup Instructions

### 1. Clone the Repository

```bash
https://github.com/mohammadshahnawazngp7/Rails_auth_app.git
cd Rails_auth_app

```
## 2. Install Dependencies
Ensure you have Ruby, PostgreSQL, and Bundler installed.
```bash
bundle install
```

## 3. Setup Environment Variables
Copy the example .env and configure:
```bash
cp .env.example .env
```
Then edit .env with your own values (e.g. Stytch keys, database URLs).

## 4. Database Setup

```bash
bin/rails db:create
bin/rails db:migrate
```

## 5. Run the App
```bash
bin/rails server
```

## 6.Running the Test Suite
This project uses RSpec and FactoryBot for testing.

```bash
bin/rspec
```
To run a specific test:
```bash
bin/rspec spec/models/user_spec.rb
```
