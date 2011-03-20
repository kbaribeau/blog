require File.dirname(__FILE__) + '/../../spec_helper'

describe Admin::SessionsController do
  describe 'handling GET to new' do
    before(:each) do
      get :new
    end

    it "should be successful" do
      response.should be_success
    end

    it "should render index template" do
      response.should render_template('new')
    end
  end

  describe 'handling DELETE to destroy' do
    before(:each) do
      delete :destroy
    end

    it 'logs out the current session' do
      session[:logged_in].should == false
    end

    it 'redirects to /' do
      response.should be_redirect
      response.should redirect_to('/')
    end
  end
end

shared_examples_for "logged in and redirected to /admin" do
  it "should set session[:logged_in]" do
    session[:logged_in].should be_true
  end
  it "should redirect to admin posts" do
    response.should be_redirect
    response.should redirect_to('/admin')
  end
end
shared_examples_for "not logged in" do
  it "should not set session[:logged_in]" do
    session[:logged_in].should be_nil
  end
  it "should render redirect to google auth" do
    response.should be_redirect
  end
end

shared_examples_for "failed login" do

  it "should not set session[:logged_in]" do
    session[:logged_in].should be_nil
  end

  it "should render the new action" do
    response.should render_template('new')
  end
end

describe Admin::SessionsController, "handling CREATE with post" do
  before do
    @controller.instance_eval { flash.extend(DisableFlashSweeping) }
  end

  def stub_open_id_authenticate(url, status_code, return_value)
    status = mock("Result", :successful? => status_code == :successful, :message => '')
    @controller.stub!(:enki_config).and_return(
      mock("enki_config", 
        :author_open_ids => [
          "http://enkiblog.com",
          "http://secondaryopenid.com"
        ].map {|uri| URI.parse(uri)}
      )
    )
    @controller.should_receive(:authenticate_with_open_id).with(url).and_yield(status,url).and_return(return_value)
  end

  describe "with valid URL http://enkiblog.com and OpenID authentication succeeding" do
    before do
      stub_open_id_authenticate("http://enkiblog.com", :successful, false)
      post :create, :openid_url => "http://enkiblog.com"
    end
    it_should_behave_like "logged in and redirected to /admin"
  end

  describe "with valid URL http://enkiblog.com and OpenID authentication returning 'failed'" do
    before do
      stub_open_id_authenticate("http://enkiblog.com", :failed, true)
      post :create, :openid_url => "http://enkiblog.com"
    end
    it_should_behave_like "failed login"
  end

  describe "with valid URL http://enkiblog.com and OpenID authentication returning 'missing'" do
    before do
      stub_open_id_authenticate("http://enkiblog.com", :missing, true)
      post :create, :openid_url => "http://enkiblog.com"
    end
    it_should_behave_like "failed login"
  end
  
  describe "with valid URL http://enkiblog.com and OpenID authentication returning 'canceled'" do
    before do
      stub_open_id_authenticate("http://enkiblog.com", :canceled, true)
      post :create, :openid_url => "http://enkiblog.com"
    end
    it_should_behave_like "failed login"
  end

end
