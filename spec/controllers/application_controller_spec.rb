RSpec.describe ApplicationController do
  let(:organization) { create(:organization) }

  describe "current_organization" do
    before(:each) do
      allow(controller).to receive(:current_user).and_return(user)
      allow(controller).to receive(:current_role).and_return(user.roles.first)
    end

    context "As a partner user" do
      let(:user) { create(:partner_user) }
      it "should return nil" do
        expect(controller.current_organization).to eq(nil)
      end
    end

    context "As an org user" do
      let(:org) { create(:organization) }
      let(:org2) { create(:organization) }
      let(:user) { create(:user, organization: org) }
      before(:each) do
        user.add_role(Role::ORG_USER, org2) # add a second role
      end
      it "should return the first org role" do
        expect(controller.current_organization).to eq(org)
      end

      context "with a changed current role" do
        before(:each) do
          allow(controller).to receive(:current_role).and_return(user.roles.last)
        end
        it "should return the first org role" do
          expect(controller.current_organization).to eq(org2)
        end
      end
    end
  end

  describe "current_partner" do
    before(:each) do
      allow(controller).to receive(:current_user).and_return(user)
      allow(controller).to receive(:current_role).and_return(user.roles.first)
    end

    context "As an org user" do
      let(:user) { create(:user, organization: organization) }
      it "should return nil" do
        expect(controller.current_partner).to eq(nil)
      end
    end

    context "As a partner user" do
      let(:partner) { create(:partner, organization: organization) }
      let(:partner2) { create(:partner, organization: organization) }
      let(:user) { create(:partner_user, partner: partner) }
      before(:each) do
        user.add_role(Role::PARTNER, partner2) # add a second role
      end
      it "should return the first partner role" do
        expect(controller.current_partner).to eq(partner)
      end

      context "with a changed current role" do
        before(:each) do
          allow(controller).to receive(:current_role).and_return(user.roles.last)
        end
        it "should return the first partner role" do
          expect(controller.current_partner).to eq(partner2)
        end
      end
    end
  end

  describe "dashboard_path_from_current_role" do
    before(:each) do
      allow(controller).to receive(:current_user).and_return(user)
      allow(controller).to receive(:current_role).and_return(user.roles.first)
    end

    context "As a super admin" do
      let(:user) { create(:super_admin) }

      it "links to the admin dashboard" do
        allow(controller).to receive(:current_role)
          .and_return(user.roles.find { |r| r.name == Role::SUPER_ADMIN.to_s })
        expect(controller.dashboard_path_from_current_role).to match %r{/admin/dashboard.*}
      end
    end

    context "As a user without super admin status" do
      let(:user) { create(:super_admin, organization: organization) }

      it "links to the general dashboard" do
        expect(controller.dashboard_path_from_current_role).to eq "/dashboard"
      end
    end
  end

  context "when user input date range is invalid" do
    controller do
      def setup_date_range_picker
        super
      end
    end

    before(:each) do
      # {"filters"=>{"date_range"=>"January 12, 2025 - January 13, 2025", "date_range_label"=>"since 2025-01-12", "by_type"=>"", "by_storage_location"=>"", "by_item"=>""}, "button"=>"", "controller"=>"events", "action"=>"index"}

      allow(controller).to receive(:params).and_return({"filters"=>{"date_range"=>"nov 08 to feb 08", "date_range_label"=>"since 2025-01-12"}, "controller"=>"distributions", "action"=>"index"})
      controller.setup_date_range_picker
    end

    it "should flash an error message" do
      expect(flash[:error]).to eq("Date range not properly formatted.")
    end

    it "should reset the date range to the default date value" do
      expect(:params["filters"]["date_range"]).to eq(helpers.default_date)
    end

    it "should redirect to the correct controller and action" do
      expect(controller).to receive(:redirect_to).with("distributions", "index")
    end
  end
end
