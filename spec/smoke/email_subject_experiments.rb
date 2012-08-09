require 'smoke_spec_helper'
require 'nokogiri'

describe "creating an email subject experiment" do
  it "awards a win against the email subject when email recipient signs" do
    petition = create_a_featured_petition({title: "Multiple email subjects!", description: "Yes indeed", email_subjects: ["Subject A", "Subject B"]})
    member = create_member
    email = send_petition_email petition, member

    experiment = email_experiment_results_for petition
    experiment.spins.should == 1
    experiment.wins.should == 0

    email_as_html = Nokogiri::HTML(email)
    petition_link = email_as_html.xpath("//a[text()='Please, click here to sign now!']/@href").to_s
    go_to petition_link
    sign_petition

    experiment = email_experiment_results_for petition
    experiment.spins.should == 1
    experiment.wins.should == 1
  end

  it "editing subject should start a new test" do
    pending 'Someone has to implement it :)'
    # go back to editing your petition
    # change both of the subjects
    # save
    # send an email
    # visit /admin/experiments
    # make sure the number of spins is 1 and wins 1 for the old subject
    # make sure the number of spins is 1 for a new subject
  end
end


def email_experiment_results_for petition
  as_admin do
    go_to 'admin/experiments?f=petitions'
    table = element(xpath: "//table[@id = 'petition #{petition.id} email title']")
    spins = table.find_element(xpath: "tbody/tr/td[@class='spins']").text.to_i
    wins = table.find_element(xpath: "tbody/tr/td[@class='wins']").text.to_i
    return OpenStruct.new(spins: spins, wins: wins)
  end
end

def send_petition_email petition, member
  as_admin do
    on_demand_email_path = "admin/on_demand_email/new?petition_id=#{petition.id}&member_id=#{member.id}"
    go_to on_demand_email_path
    return $driver.page_source
  end
end
