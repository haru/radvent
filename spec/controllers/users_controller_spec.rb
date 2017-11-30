require 'rails_helper'

RSpec.describe UsersController, :type => :controller do
  before do
    @user = create(:user, admin: true)
    sign_in @user
  end
  describe "GET index" do
    it "returns http success" do
      get :index
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET #edit_info" do
    it "assigns @menu as :users" do
      get :edit_info, params: {id: @user}
      expect(assigns(:menu)).to eq :users
    end

    it "renders the :edit_info template" do
      get :edit_info, params: {id: @user}
      expect(response).to render_template :edit_info
    end
  end

  describe "PUT #update_info" do
    it "assigns @user as requested user" do
      user = create(:user, admin: false)
      put :update_info, params: {id: user, user:{email: "aaa@bbb.com"}, name: "newname", admin: true}
      updated_user = assigns(:user)
      expect(updated_user.id).to eq user.id
      expect(updated_user.email).to eq "aaa@bbb.com"
      expect(updated_user.admin).to eq false
    end

    it "redirect to edit_user_path when update successful." do
      user = create(:user, admin: false)
      put :update_info, params: {id: user, user:{email: "aaa@bbb.com"}, name: "newname", admin: true}
      expect(response).to redirect_to edit_user_path(id: user)
    end

    it "renders the :edit_info template when update fail" do
      user = create(:user, admin: false)
      put :update_info, params: {id: user, user:{email: ""}, name: "", admin: true}
      expect(response).to render_template :edit_info
    end
  end

  describe "delete #destroy" do
    it "delete requested user" do
      user = create(:user, admin: false)
      delete :destroy, params: {id: user}
      expect(User.find_by(id: user.id)).to eq nil
    end

    it "redirect to users_path" do
      user = create(:user, admin: false)
      delete :destroy, params: {id: user}
      expect(response).to redirect_to users_path
    end
  end

end
