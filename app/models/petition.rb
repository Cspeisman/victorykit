require 'whiplash'

class Petition < ActiveRecord::Base
  include Bandit

  attr_accessible :description, :title, :petition_titles_attributes
  attr_accessible :description, :title, :petition_titles_attributes, :to_send, :as => :admin
  has_many :signatures
  has_many :sent_emails
  has_many :petition_titles, :dependent => :destroy
  belongs_to :owner, class_name:  "User"
  validates_presence_of :title, :description, :owner_id
  validates_with PetitionTitlesValidator
  before_validation :strip_whitespace
  accepts_nested_attributes_for :petition_titles, :reject_if => lambda { |a| a[:title].blank? }, :allow_destroy => true

  def has_edit_permissions(current_user)
    return false if current_user.nil?
    owner.id == current_user.id || current_user.is_admin || current_user.is_super_user
  end

  def self.find_interesting_petitions_for(member)
    Petition.find_all_by_to_send(true) -
      Signature.find_all_by_member_id(member).map{|s| s.petition} -
      SentEmail.find_all_by_member_id(member).map{|e| e.petition}
  end

  def strip_whitespace
    self.title.strip! unless self.title.nil?
  end

  def facebook_title
    alternate_title PetitionTitle::TitleType::FACEBOOK
  end

  private

  def alternate_title title_type
    alt_titles = petition_titles.find_all_by_title_type(title_type)
    test_name = "petition #{id} #{title_type} title"
    chosen = spin! test_name, :signature, alt_titles, {:session_id => id} if alt_titles.any?
    chosen || PetitionTitle.new(title: title, title_type: PetitionTitle::TitleType::DEFAULT)
  end
end