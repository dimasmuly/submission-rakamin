require 'rails_helper'

RSpec.describe "Api::V1::Portfolios", type: :request do
  # We are setting up two tenants to test the IDOR bug
  let(:tenant_a) { Organization.create!(name: "Tenant A", scheme: "tenanta", identifier: "A", host: "a.test") }
  let(:tenant_b) { Organization.create!(name: "Tenant B", scheme: "tenantb", identifier: "B", host: "b.test") }

  let(:user_a) { User.create!(email: "a@test.com", password: "password", role: "assessor") }
  
  # Assessment for Tenant B
  let(:assessment_b) do 
    Assessment.create!(name: "Test B", time_limit_min: 30, tenant_id: tenant_b.id, created_by: user_a.id)
  end

  # Session for Tenant B
  let(:session_b) do
    Session.create!(assessment: assessment_b, tenant_id: tenant_b.id, status: 'active')
  end

  # Portfolio for Tenant B
  let(:portfolio_b) do
    Portfolio.create!(session: session_b, generation_status: 'complete')
  end

  before do
    # Add a portfolio skill to check ai_level
    portfolio_b.portfolio_skills.create!(
      skill_label: 'Ruby', 
      is_discovered: true, 
      ai_level: 3, 
      ai_confidence: 'high', 
      competency_summary: 'Good'
    )
  end

  def auth_headers(user, tenant)
    # The API uses JWT, so we mock the decoded claims using AuthorizeApiRequest
    # For a real test we'd generate a token, but let's just stub the AuthorizeApiRequest
    # or actually generate the JWT if possible. 
    # Let's generate a real JWT using the app's secret if available.
    token = JsonWebToken.encode({ user_id: user.id, role: user.role, scheme: tenant.scheme })
    { "Authorization" => "Bearer #{token}" }
  end

  describe "GET /api/v1/portfolios/:id/export" do
    it "prevents IDOR: Tenant A cannot access Tenant B's portfolio" do
      # Attempt to access Tenant B's portfolio while authenticated as Tenant A
      get "/api/v1/portfolios/#{portfolio_b.id}/export", headers: auth_headers(user_a, tenant_a)
      
      # It should be not_found, but currently it returns 200 due to IDOR
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /api/v1/sessions/:id/portfolio" do
    it "returns ai_level as a string (L1-L5) to match frontend types" do
      # Make sure we're tenant B to access tenant B's session legitimately
      get "/api/v1/sessions/#{session_b.id}/portfolio", headers: auth_headers(user_a, tenant_b)
      
      expect(response).to have_http_status(:ok)
      
      json = JSON.parse(response.body)
      skill = json['portfolio']['skills'].first
      
      # The frontend strictly expects a string like "L3", not an integer 3
      expect(skill['ai_level']).to eq('L3')
    end
  end
end
