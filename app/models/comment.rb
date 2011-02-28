#   Copyright (c) 2010, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.

class Comment < ActiveRecord::Base
  require File.join(Rails.root, 'lib/diaspora/web_socket')
  require File.join(Rails.root, 'lib/youtube_titles')
  include YoutubeTitles
  include ROXML

  include Diaspora::Webhooks
  include Diaspora::Relayable
  include Diaspora::Guid

  include Diaspora::Socketable

  xml_attr :text
  xml_attr :diaspora_handle

  belongs_to :post, :touch => true
  belongs_to :person

  validates_presence_of :text, :post
  validates_length_of :text, :maximum => 2500

  serialize :youtube_titles, Hash
  before_save do
    get_youtube_title text
    self.text.strip! unless self.text.nil?
  end
  def diaspora_handle
    person.diaspora_handle
  end
  def diaspora_handle= nh
    self.person = Webfinger.new(nh).fetch
  end

  def notification_type(user, person)
    if self.post.person == user.person
      return "comment_on_post"
    elsif self.post.comments.where(:person_id => user.person.id) != [] && self.person_id != user.person.id
      return "also_commented"
    else
      return false
    end
  end

  def parent_class
    Post
  end

  def parent
    self.post
  end

  def parent= parent
    self.post = parent
  end
end
