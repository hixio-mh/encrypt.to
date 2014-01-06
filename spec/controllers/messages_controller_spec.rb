require "spec_helper"

describe MessagesController do
  
  let(:user) { create :user }
  
  before {
    email = "hello@encrypt.to"
    short_keyid = "0x11489A1F"
    long_keyid = "0x0caf1e5b11489a1f"
    vindex_response = "info:1:2\npub:11489A1F:1:2048:1387447945::\nuid:Encrypt.to <hello@encrypt.to>:1387447945::\n\r\n"
    
    stub_request(:get, "http://pgpkey.org/pks/lookup?exact=on&op=vindex&options=mr&search=#{email}").
      with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
      to_return(:status => 200, :body => vindex_response, :headers => {})
    stub_request(:get, "http://pgpkey.org/pks/lookup?op=get&options=mr&search=#{short_keyid}").
      with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
      to_return(:status => 200, :body => user.public_key, :headers => {})
    stub_request(:get, "http://pgpkey.org/pks/lookup?fingerprint=on&op=vindex&options=mr&search=#{short_keyid}").
      with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
      to_return(:status => 200, :body => vindex_response, :headers => {})
    stub_request(:get, "http://pgpkey.org/pks/lookup?fingerprint=on&op=vindex&options=mr&search=#{long_keyid}").
      with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
      to_return(:status => 200, :body => vindex_response, :headers => {})
    stub_request(:get, "http://pgpkey.org/pks/lookup?op=get&options=mr&search=#{long_keyid}").
      with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
      to_return(:status => 200, :body => user.public_key, :headers => {})
  }    
    
  describe "GET new" do
    it "has a 302 status code if params empty" do
      get :new
      expect(response.status).to eq(302)
    end
  end
  
  describe "GET new" do
    it "has a 200 status code if params uid is local user" do
      get :new, uid: user.username
      expect(assigns(:pubkey)).to eq(user.public_key)
      expect(response.status).to eq(200)
    end
  end

  describe "GET new" do
    it "has a 200 status code if params uid is email" do
      get :new, uid: "hello@encrypt.to"
      expect(response.status).to eq(200)
      expect(assigns(:pubkey)).to eq(user.public_key)
    end
  end
  
  describe "GET new" do
    it "has a 200 status code if params uid is short keyid" do
      get :new, uid: "0x11489A1F"
      expect(response.status).to eq(200)
      expect(assigns(:pubkey)).to eq(user.public_key)
    end
  end
  
  describe "GET new" do
    it "has a 200 status code if params uid is long keyid" do
      get :new, uid: "0x0caf1e5b11489a1f"
      expect(response.status).to eq(200)
      expect(assigns(:pubkey)).to eq(user.public_key)
    end
  end
  
  describe "POST message" do
    it "has a 302 status code if params are valid" do
      message = "-----BEGIN PGP MESSAGE-----\nVersion: OpenPGP.js v.1.20130306\nComment: http://openpgpjs.org\n\nwcBMA3VR7lR02L1RAQf/T/DHX8b1Ka65EpXZcffKjgzYch11Kvm0SJcXne0G\n2M/k3vAsKnru+zsbOnV+9IpXIywJIyDWOFasrqZggmHlMVOSr5CjKX27RspY\nfRPJ/9AU+Oada0iqocMIexY1QkoeGO16je0QWd7sbq+ejZZbJwfSvG/orW87\nHhX/r0pfUEpcwSNQcc4588NQ6qRvi9QwXt+Ykktozqi+JGurWOotLwe4/SQk\nJ2PePxYX6hBP1mUW7WVIHL3imM44Fe4x8yhFCVWpZDeKY1aA4B5Sg4STuuCJ\nnUgnpoeC4lDX+PyEoFq+QUi1sTHWdrZq6u8LUYX/Ode6tW/olVxYOoabWZ3y\nUtI4AZITMAgOOeDueWxbR214x3wqMQc7W1IuZWpzL4ogE+zjWwHU1j6EgD31\npEnyQbmBDMgGlxPqcis=\n=W15x\n-----END PGP MESSAGE-----"
      from = "hello@encrypt.to"
      post :create, :message => { to: user.email, from: from, body: message }
      expect(response.status).to eq(302)
      flash[:notice].should match('Encrypted message sent! Thanks.')
      ActionMailer::Base.deliveries[ActionMailer::Base.deliveries.size-2].to.should == [user.email]
      ActionMailer::Base.deliveries.last.to.should == [from]
    end
  end
  
  describe "POST message" do
    it "has a 302 status code if params are invalid" do
      message = ""
      from = "hello@encrypt.to"
      post :create, :message => { to: user.email, from: from, body: message }
      expect(response.status).to eq(302)
      flash[:notice].should match('Sorry something went wrong. Try again!')
    end
  end

end
