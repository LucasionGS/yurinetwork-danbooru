require 'test_helper'

class BanTest < ActiveSupport::TestCase
  context "A ban" do
    context "created by an admin" do
      setup do
        @banner = FactoryBot.create(:admin_user)
        CurrentUser.user = @banner
      end

      teardown do
        @banner = nil
        CurrentUser.user = nil
      end

      should "set the is_banned flag on the user" do
        user = FactoryBot.create(:user)
        ban = FactoryBot.build(:ban, :user => user, :banner => @banner)
        ban.save
        user.reload
        assert(user.is_banned?)
      end

      should "be valid" do
        user = FactoryBot.create(:user)
        ban = FactoryBot.create(:ban, :user => user, :banner => @banner)
        assert(ban.errors.empty?)
      end
    end

    should "initialize the expiration date" do
      user = FactoryBot.create(:user)
      admin = FactoryBot.create(:admin_user)
      CurrentUser.scoped(admin) do
        ban = FactoryBot.create(:ban, :user => user, :banner => admin)
        assert_not_nil(ban.expires_at)
      end
    end

    should "update the user's feedback" do
      user = FactoryBot.create(:user)
      admin = FactoryBot.create(:admin_user)
      assert(user.feedback.empty?)
      CurrentUser.scoped(admin) do
        FactoryBot.create(:ban, :user => user, :banner => admin)
      end
      assert(!user.feedback.empty?)
      assert_equal("negative", user.feedback.last.category)
    end
  end

  context "Searching for a ban" do
    should "find a given ban" do
      CurrentUser.user = FactoryBot.create(:admin_user)

      user = FactoryBot.create(:user)
      ban = FactoryBot.create(:ban, user: user)
      params = {
        user_name: user.name,
        banner_name: ban.banner.name,
        reason: ban.reason,
        expired: false,
        order: :id_desc
      }

      bans = Ban.search(params)

      assert_equal(1, bans.length)
      assert_equal(ban.id, bans.first.id)
    end

    context "by user id" do
      setup do
        @admin = FactoryBot.create(:admin_user)
        CurrentUser.user = @admin
        @user = FactoryBot.create(:user)
      end

      teardown do
        CurrentUser.user = nil
      end
    end
  end
end
