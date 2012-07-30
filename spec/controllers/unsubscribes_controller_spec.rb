require 'spec_helper'

describe UnsubscribesController do
  
  describe "GET new" do
    it "assigns a new unsubscribe as @unsubscribe" do
      get :new
      assigns(:unsubscribe).should be_a_new(Unsubscribe)
    end
    it "assigns the email hash, if available" do
      get :new, n: "i'm a hash!"
      assigns(:email_hash).should == "i'm a hash!"
    end
  end

  describe "POST create" do   
    let(:member) {create :member}
    
    context "with valid params" do
      before :each do
        Unsubscribe.any_instance.stub(:save).and_return(true)
        a = ""
        256.times{a << "a"}
        request.env["HTTP_USER_AGENT"] = a
        post :create, unsubscribe: {email: member.email}
      end
      describe "the newly created unsubscribe" do
        subject { assigns(:unsubscribe) } 
        it { should be_a(Unsubscribe) }
        its(:cause) { should == "unsubscribed"}
        its(:ip_address) { should == "0.0.0.0"}
        a = ""
        255.times{a << "a"}
        its(:user_agent) { should == a}
      end      
    end
    
    context "with invalid params" do
      before :each do
        Unsubscribe.any_instance.stub(:save).and_return(false)
        post :create, unsubscribe: {email: member.email}
      end
      it "assigns a newly created but unsaved unsubscribe as @unsubscribe" do
        assigns(:unsubscribe).should be_a_new(Unsubscribe)
      end
      it "should redirect to new unsubscribe url" do
        response.should redirect_to new_unsubscribe_url
      end
    end

    context "when member not found" do
      before :each do
        Member.any_instance.stub(:find_by_email).and_return(nil)
        post :create, unsubscribe: {}
      end
      it "should redirect to new unsubscribe url" do
        response.should redirect_to new_unsubscribe_url
      end
    end
    
    context "referred from an email" do
      let(:sent_email) {create :sent_email, member: member}
      
      before :each do
        post :create, unsubscribe: {email: member.email}, :email_hash => SentEmailHasher.generate(sent_email.id)
      end
      it "associates the email with the unsubscribe" do
        unsubscribe = Unsubscribe.find_by_member_id member
        unsubscribe.sent_email.should == sent_email
      end
    end
  end
end
