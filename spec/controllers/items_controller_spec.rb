# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ItemsController do
  let(:user) { create(:user) }
  let(:event) do
    create(:event, name: 'test', title: 'test', start_date: '2015-12-01', end_date: '2015-12-30',
                   created_by: user, updated_by: user)
  end
  let(:advent_calendar_item_prev) { create(:advent_calendar_item, event: event, user: user, date: 1) }
  let(:advent_calendar_item) { create(:advent_calendar_item, event: event, user: user, date: 2) }
  let(:advent_calendar_item_next) { create(:advent_calendar_item, event: event, user: user, date: 3) }

  before do
    Event.destroy_all
    AdventCalendarItem.destroy_all
    Item.destroy_all
    sign_in user
    create(:item, advent_calendar_item: advent_calendar_item_prev)
    create(:item, advent_calendar_item: advent_calendar_item)
    create(:item, advent_calendar_item: advent_calendar_item_next)
  end

  describe 'GET #show' do
    before do
      today = Date.new(2015, 12, 2)
      allow(Time.zone).to receive(:today).and_return(today)
    end

    it "redirects to root if requested item's date doesn't come yet" do
      item = advent_calendar_item.item
      allow(Time.zone).to receive(:today).and_return(Date.new(2014, 12, 3))
      get :show, params: { id: item }
      expect(response).to redirect_to root_path
    end

    it 'assigns the requested item to @item' do
      item = advent_calendar_item.item
      get :show, params: { id: item.id }
      expect(assigns(:item)).to eq item
    end

    it 'assigns previous advent_calendar_item to @advent_calendar_item_prev' do
      item = advent_calendar_item.item
      get :show, params: { id: item }
      expect(assigns(:advent_calendar_item_prev)).to eq advent_calendar_item_prev
    end

    it 'assigns nil to @advent_calendar_item_prev if previous advent_calendar_item is not exist' do
      item = advent_calendar_item_prev.item
      get :show, params: { id: item }
      expect(assigns(:advent_calendar_item_prev)).to be_nil
    end

    it 'assigns next advent_calendar_item to @advent_calendar_item_next' do
      item = advent_calendar_item.item
      get :show, params: { id: item }
      expect(assigns(:advent_calendar_item_next)).to eq advent_calendar_item_next
    end

    it 'assigns nil to @advent_calendar_item_next if next advent_calendar_item is not exist' do
      item = advent_calendar_item_next.item
      get :show, params: { id: item }
      expect(assigns(:advent_calendar_item_next)).to be_nil
    end

    it "renders the :show template if item's date is passed" do
      item = advent_calendar_item_prev.item
      allow(Time.zone).to receive(:today).and_return(Date.new(2016, 11, 2))
      get :show, params: { id: item }
      expect(response).to render_template :show
    end
  end

  describe 'GET #show edit button for the author' do
    render_views

    before do
      allow(Time.zone).to receive(:today).and_return(Date.new(2015, 12, 2))
      sign_in user
      get :show, params: { id: advent_calendar_item.item.id }
    end

    it 'shows the edit button linking to the item edit page' do
      expect(response.body).to include("href=\"/items/#{advent_calendar_item.item.id}/edit\"")
    end
  end

  describe 'GET #show edit button for a non-author' do
    render_views

    before do
      allow(Time.zone).to receive(:today).and_return(Date.new(2015, 12, 2))
      sign_in create(:user)
      get :show, params: { id: advent_calendar_item.item.id }
    end

    it 'does not show the edit button' do
      expect(response.body).not_to include("href=\"/items/#{advent_calendar_item.item.id}/edit\"")
    end
  end

  describe 'GET #show comment delete button' do
    render_views

    include_context 'with a board item world'

    let(:today) { Date.new(2015, 12, 2) }
    let(:item_date) { 2 }
    let(:delete_button) { %r{action="/comments/\d+"} }

    before do
      create(:comment, item: world[:item], user_name: 'alice', body: 'first')
      create(:comment, item: world[:item], user_name: 'bob', body: 'second')
      # The file-level sign_in is not wanted here; each example picks its own role.
      sign_out user
    end

    [nil, :member, :author, :outsider].each do |role|
      it "does not show delete buttons to #{role || 'anonymous'} but shows the comments", :aggregate_failures do
        sign_in world[role] if role
        get :show, params: { id: world[:item].id }
        expect(response.body).to include('alice').and include('second')
        expect(response.body.scan(delete_button)).to be_empty
      end
    end

    %i[owner admin].each do |role|
      it "shows a delete button on every comment to #{role}", :aggregate_failures do
        sign_in world[role]
        get :show, params: { id: world[:item].id }
        expect(response.body.scan(delete_button).size).to eq 2
        expect(response.body).to include('alice').and include('second')
      end
    end
  end

  describe 'GET #new' do
    let!(:new_slot) { create(:advent_calendar_item, event: event, user: user, date: 12) }

    it 'assigns the requested date to @date' do
      get :new, params: { id: new_slot.id, date: 1 }
      expect(assigns(:date)).to eq '1'
    end

    it 'assigns a new item to @item' do
      get :new, params: { id: new_slot.id }
      expect(assigns(:item)).to be_a_new(Item)
    end

    it 'assigns the requested id to @item.advent_calendar_item_id' do
      get :new, params: { id: new_slot.id }
      expect(assigns(:item).advent_calendar_item_id).to eq new_slot.id
    end

    it 'assigns a new attachment to @attachment' do
      get :new, params: { id: new_slot.id }
      expect(assigns(:attachment)).to be_a_new(Attachment)
    end

    it 'assigns the requested id to @attachment.advent_calendar_item_id' do
      get :new, params: { id: new_slot.id }
      expect(assigns(:attachment).advent_calendar_item_id).to eq new_slot.id
    end

    it 'renders the :new template' do
      get :new, params: { id: new_slot.id }
      expect(response).to render_template :new
    end

    context 'when rendering the view' do
      render_views

      it 'returns http success' do
        get :new, params: { id: new_slot.id, date: new_slot.date }
        expect(response).to have_http_status(:success)
      end
    end

    context 'when rendering the view without an advent_calendar_item id' do
      render_views

      it 'returns not found' do
        get :new
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'GET #edit' do
    it 'assigns the requested item to @item' do
      aci = create(:advent_calendar_item, date: 4, event: event, user: user)
      item = aci.item
      get :edit, params: { use_route: :radvent, id: item }
      expect(assigns(:item)).to eq item
    end

    it 'renders the :edit template' do
      item = advent_calendar_item.item
      get :edit, params: { use_route: :radvent, id: item }
      expect(response).to render_template :edit
    end

    it 'returns not found when the requested item is not found' do
      non_existent_id = Item.maximum(:id).to_i + 1
      get :edit, params: { use_route: :radvent, id: non_existent_id }
      expect(response).to have_http_status(:not_found)
    end

    context 'when rendering the view' do
      render_views

      it 'returns http success' do
        item = advent_calendar_item.item
        get :edit, params: { use_route: :radvent, id: item }
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'POST #create' do
    it 'saves the new item in the database' do
      aci = create(:advent_calendar_item, date: 8, event: event, user: user)
      expect do
        post :create, params: { item: build(:item, advent_calendar_item: aci).attributes }
      end.to change(Item, :count).by(1)
    end

    it 'renders the :new if the new item is not saved' do
      aci = create(:advent_calendar_item, date: 8, event: event, user: user)
      allow_any_instance_of(Item).to receive(:save).and_return(false)
      post :create, params: { item: attributes_for(:item, advent_calendar_item_id: aci.id) }
      expect(response).to render_template :new
    end

    context 'when rendering the view after a failed save' do
      render_views

      it 'returns http unprocessable content' do
        aci = create(:advent_calendar_item, date: 8, event: event, user: user)
        allow_any_instance_of(Item).to receive(:save).and_return(false)
        post :create, params: { item: attributes_for(:item, advent_calendar_item_id: aci.id) }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    it 'redirects to advent_calendar_items#show if the new item is saved' do
      aci = create(:advent_calendar_item, date: 9, event: event, user: user)
      post :create, params: { item: build(:item, advent_calendar_item: aci).attributes }
      expect(response).to redirect_to advent_calendar_item_path(id: aci)
    end
  end

  describe 'PATCH #update' do
    let(:item) { advent_calendar_item.item }

    it 'locates the requested @item' do
      patch :update, params: { id: item, item: attributes_for(:item) }
      expect(assigns(:item)).to eq(item)
    end

    context 'with valid attributes' do
      before do
        attrs = attributes_for(:item, title: 'title_updated', body: 'body_updated')
        patch :update, params: { id: item, item: attrs }
        item.reload
      end

      it 'updates title' do
        expect(item.title).to eq('title_updated')
      end

      it 'updates body' do
        expect(item.body).to eq('body_updated')
      end
    end

    it 'renders the :edit if the item is not updated' do
      allow_any_instance_of(Item).to receive(:save).and_return(false)
      patch :update, params: { id: item, item: attributes_for(:item) }
      expect(response).to render_template :edit
    end

    context 'when rendering the view after a failed save' do
      render_views

      it 'returns http unprocessable content' do
        allow_any_instance_of(Item).to receive(:save).and_return(false)
        patch :update, params: { id: item, item: attributes_for(:item) }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    it 'redirects to advent_calendar_items#show if the item is updated' do
      patch :update, params: { id: item, item: attributes_for(:item) }
      expect(response).to redirect_to advent_calendar_item_path(item.advent_calendar_item_id)
    end
  end

  describe 'GET #show on a private board' do
    render_views

    let(:owner) { create(:user) }
    let(:board) { create(:board, :private_user, owner: owner, name: 'Secret Board Name') }
    let(:private_aci) do
      event = create(:event, board: board, name: 'secret-cal', title: 'Secret Calendar',
                             start_date: '2015-12-01', end_date: '2015-12-30', created_by: owner, updated_by: owner)
      create(:advent_calendar_item, event: event, user: owner, user_name: owner.name, date: 2)
    end
    let!(:private_item) do
      create(:item, advent_calendar_item: private_aci, title: 'Secret Article Title', body: 'Secret article body')
    end

    before do
      allow(Time.zone).to receive(:today).and_return(Date.new(2015, 12, 2))
    end

    shared_examples 'a hidden article' do
      before { get :show, params: { id: private_item.id } }

      it 'responds with 404' do
        expect(response).to have_http_status(:not_found)
      end

      it 'renders the not-found page' do
        expect(response).to render_template('errors/notfound')
      end

      it 'does not leak the board name, title or body' do
        expect(response.body).not_to include('Secret Board Name', 'Secret Article Title', 'Secret article body')
      end
    end

    shared_examples 'a readable article' do
      before { get :show, params: { id: private_item.id } }

      it 'renders the article' do
        expect(response).to render_template :show
      end
    end

    context 'when the viewer is a guest' do
      before { sign_out user }

      it_behaves_like 'a hidden article'
    end

    context 'when the viewer is signed in but not a member' do
      before { sign_in create(:user) }

      it_behaves_like 'a hidden article'
    end

    context 'when the viewer wrote the article but is no longer a member' do
      before do
        author = create(:user)
        private_aci.update!(user: author)
        create(:board_membership, board: board, user: author).destroy!
        sign_in author
      end

      it_behaves_like 'a hidden article'
    end

    context 'when the viewer is a guest and the article is not yet published' do
      before do
        allow(Time.zone).to receive(:today).and_return(Date.new(2015, 11, 30))
        sign_out user
      end

      it_behaves_like 'a hidden article'
    end

    context 'when the board has just been changed from private to public and the viewer is a guest' do
      before do
        board.update!(visibility: :public)
        sign_out user
      end

      it_behaves_like 'a readable article'
    end

    context 'when the board has just been changed from public to private and the viewer is a guest' do
      let(:board) { create(:board, :public_user, owner: owner, name: 'Secret Board Name') }

      before do
        board.update!(visibility: :private)
        sign_out user
      end

      it_behaves_like 'a hidden article'
    end

    context 'when the board is public and the viewer is a guest' do
      let(:board) { create(:board, :public_user, owner: owner, name: 'Secret Board Name') }

      before { sign_out user }

      it_behaves_like 'a readable article'
    end

    context 'when the board is protected and the viewer is a guest' do
      let(:board) { create(:board, :protected_user, owner: owner, name: 'Secret Board Name') }

      before { sign_out user }

      it_behaves_like 'a readable article'
    end

    context 'when the viewer is the board owner' do
      before { sign_in owner }

      it_behaves_like 'a readable article'
    end

    context 'when the viewer is a board member' do
      before do
        member = create(:user)
        create(:board_membership, board: board, user: member)
        sign_in member
      end

      it_behaves_like 'a readable article'
    end

    context 'when the viewer is a system admin' do
      before { sign_in create(:user, admin: true) }

      it_behaves_like 'a readable article'
    end

    context 'when the owner opens an article that is not yet published' do
      before do
        allow(Time.zone).to receive(:today).and_return(Date.new(2015, 11, 30))
        sign_in owner
        get :show, params: { id: private_item.id }
      end

      it 'redirects to root as before' do
        expect(response).to redirect_to root_path
      end
    end

    context 'when the article does not exist' do
      before do
        sign_out user
        get :show, params: { id: Item.maximum(:id) + 1 }
      end

      it 'renders the not-found page' do
        expect(response).to render_template('errors/notfound')
      end

      it 'does not mention the board name' do
        expect(response.body).not_to include('Secret Board Name')
      end
    end
  end

  describe 'preview routing' do
    it 'routes POST /items/preview to items#preview_new' do
      expect(post: '/items/preview').to route_to(controller: 'items', action: 'preview_new')
    end

    it 'keeps preview_items_path pointing at /items/preview' do
      expect(preview_items_path).to eq '/items/preview'
    end

    %i[get post patch].each do |verb|
      it "routes #{verb.upcase} /items/:id/preview to items#preview" do
        expect(verb => '/items/1/preview').to route_to(controller: 'items', action: 'preview', id: '1')
      end
    end
  end

  describe 'article authorization' do
    let(:slot_owner) { create(:user) }
    let(:slot_event) do
      create(:event, board: create(:board, :public_user, owner: slot_owner), name: 'auth-item-cal',
                     title: 'Auth Item Calendar', start_date: '2015-12-01', end_date: '2015-12-25',
                     created_by: slot_owner, updated_by: slot_owner)
    end
    let!(:slot_with_item) { create(:advent_calendar_item, event: slot_event, user: slot_owner, date: 7) }

    before do
      allow(Time.zone).to receive(:today).and_return(Date.new(2015, 11, 30))
      create(:item, advent_calendar_item: slot_with_item, title: 'existing title', body: 'existing body')
    end

    # Returns an empty slot of the slot owner, creating it once per example.
    #
    # @return [AdventCalendarItem]
    def empty_slot
      @empty_slot ||= create(:advent_calendar_item, event: slot_event, user: slot_owner, date: 5)
    end

    # Returns a slot on a board the requester cannot see, creating it once per example.
    #
    # @return [AdventCalendarItem]
    def invisible_slot
      @invisible_slot ||= begin
        board = create(:board, :private_user, owner: slot_owner)
        event = create(:event, board: board, name: 'auth-item-private', title: 'Auth Item Private',
                               start_date: '2015-12-01', end_date: '2015-12-25', created_by: slot_owner,
                               updated_by: slot_owner)
        create(:advent_calendar_item, event: event, user: slot_owner, date: 6)
      end
    end

    # Builds the article attributes posted to create and update.
    #
    # @param slot_id [Integer] the advent calendar item id sent in the request
    # @param title [String] the article title
    # @param body [String] the article body
    # @return [Hash] the item attributes
    def article_attributes(slot_id, title: 'new title', body: 'new body')
      { title: title, body: body, advent_calendar_item_id: slot_id }
    end

    # Posts an article creation request for the given slot id.
    #
    # @param slot_id [Integer] the advent calendar item id sent in the request
    # @return [void]
    def post_article(slot_id)
      post :create, params: { item: article_attributes(slot_id) }
    end

    context 'when a non-admin user targets a visible slot of another user' do
      before { sign_in user }

      it 'returns 403 for new' do
        get :new, params: { id: empty_slot.id }
        expect(response).to have_http_status(:forbidden)
      end

      it 'returns 403 and creates nothing for create', :aggregate_failures do
        expect { post_article(empty_slot.id) }.not_to change(Item, :count)
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when the slot is on a board the user cannot see or does not exist' do
      before { sign_in user }

      it 'returns 404 for new on an invisible slot' do
        get :new, params: { id: invisible_slot.id }
        expect(response).to have_http_status(:not_found)
      end

      it 'returns 404 and creates nothing for create on an invisible slot', :aggregate_failures do
        expect { post_article(invisible_slot.id) }.not_to change(Item, :count)
        expect(response).to have_http_status(:not_found)
      end

      it 'returns 404 for new on a non-existent slot' do
        get :new, params: { id: AdventCalendarItem.maximum(:id).to_i + 1 }
        expect(response).to have_http_status(:not_found)
      end

      it 'returns 404 and creates nothing for create on a non-existent slot', :aggregate_failures do
        expect { post_article(AdventCalendarItem.maximum(:id).to_i + 1) }.not_to change(Item, :count)
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when the slot owner writes before the publish date' do
      before { sign_in slot_owner }

      it 'returns success for new' do
        get :new, params: { id: empty_slot.id }
        expect(response).to have_http_status(:success)
      end

      it 'creates the article and redirects to the slot page', :aggregate_failures do
        expect { post_article(empty_slot.id) }.to change(Item, :count).by(1)
        expect(response).to redirect_to(advent_calendar_item_path(id: empty_slot.id))
      end
    end

    context 'when admin writes to the slot of another user' do
      before { sign_in create(:user, admin: true) }

      it 'creates the article and redirects to the slot page', :aggregate_failures do
        expect { post_article(empty_slot.id) }.to change(Item, :count).by(1)
        expect(response).to redirect_to(advent_calendar_item_path(id: empty_slot.id))
      end
    end

    context 'when the owner targets a slot that already has an article' do
      before { sign_in slot_owner }

      it 'does not save, re-renders new and keeps the existing article', :aggregate_failures do
        expect { post_article(slot_with_item.id) }.not_to change(Item, :count)
        expect(response).to have_http_status(:unprocessable_content)
        expect(response).to render_template :new
        expect(slot_with_item.item.reload).to have_attributes(title: 'existing title',
                                                              body: 'existing body')
      end

      it 'assigns the board of the authorized slot for the layout' do
        post_article(slot_with_item.id)
        expect(assigns(:board)).to eq slot_event.board
      end
    end

    context 'when the duplicate article is rendered with views' do
      render_views

      before { sign_in slot_owner }

      it 'shows the validation error and keeps the slot id in the form', :aggregate_failures do
        post_article(slot_with_item.id)
        expect(response.body).to include('alert-danger')
        slot_input = response.body[/<input[^>]*name="item\[advent_calendar_item_id\]"[^>]*>/]
        expect(slot_input).to include(%(value="#{slot_with_item.id}"))
      end
    end

    context 'when a conflicting top-level id is sent with create' do
      before { sign_in slot_owner }

      it 'authorizes only item[advent_calendar_item_id]', :aggregate_failures do
        others_slot = create(:advent_calendar_item, event: slot_event, user: create(:user), date: 12)
        expect do
          post :create, params: { id: empty_slot.id, item: article_attributes(others_slot.id) }
        end.not_to change(Item, :count)
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when the slot has no account and matches only by user name' do
      before { sign_in slot_owner }

      # Builds a legacy slot that has no account, saved without validation.
      #
      # @param user_name [String] the name the slot is registered under
      # @param date [Integer] the calendar date
      # @return [AdventCalendarItem]
      def legacy_slot(user_name, date)
        build(:advent_calendar_item, event: slot_event, user: nil, user_name: user_name, date: date)
          .tap { |slot| slot.save(validate: false) }
      end

      it 'allows the article when the user name matches', :aggregate_failures do
        legacy = legacy_slot(slot_owner.name, 13)
        expect { post_article(legacy.id) }.to change(Item, :count).by(1)
      end

      it 'returns 403 when the user name differs', :aggregate_failures do
        legacy = legacy_slot('someone else', 14)
        expect { post_article(legacy.id) }.not_to change(Item, :count)
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when not signed in' do
      before { sign_out user }

      it 'redirects to the sign-in page for new' do
        get :new, params: { id: empty_slot.id }
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'redirects to the sign-in page for create' do
        post_article(empty_slot.id)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    describe 'PATCH #update keeps the article on its slot' do
      before { sign_in slot_owner }

      # Patches the article with attributes pointing at the given slot id.
      #
      # @param item [Item] the article under test
      # @param slot_id [Integer] the advent calendar item id sent in the request
      # @return [void]
      def patch_article_to(item, slot_id)
        patch :update, params: { id: item,
                                 item: article_attributes(slot_id, title: 'updated title',
                                                                   body: 'updated body') }
      end

      it 'keeps the article on the original slot when another own slot is given', :aggregate_failures do
        own_other_slot = create(:advent_calendar_item, event: slot_event, user: slot_owner, date: 9)
        patch_article_to(slot_with_item.item, own_other_slot.id)
        expect(slot_with_item.item.reload.advent_calendar_item_id).to eq slot_with_item.id
        expect(slot_with_item.item.reload).to have_attributes(title: 'updated title', body: 'updated body')
        expect(response).to redirect_to(advent_calendar_item_path(id: slot_with_item.id))
      end

      it 'keeps the article on the original slot when the slot of another user is given',
         :aggregate_failures do
        others_slot = create(:advent_calendar_item, event: slot_event, user: create(:user), date: 11)
        patch_article_to(slot_with_item.item, others_slot.id)
        expect(slot_with_item.item.reload.advent_calendar_item_id).to eq slot_with_item.id
        expect(slot_with_item.item.reload).to have_attributes(title: 'updated title', body: 'updated body')
        expect(response).to redirect_to(advent_calendar_item_path(id: slot_with_item.id))
      end
    end
  end

  describe 'GET #show breadcrumb trail' do
    render_views

    before do
      allow(Time.zone).to receive(:today).and_return(Date.new(2015, 12, 2))
    end

    context 'when the article is on a user board event' do
      let(:owner) { create(:user) }
      let(:board) { create(:board, :public_user, owner: owner, name: 'Crumb Board Name') }
      let(:crumb_event) do
        create(:event, board: board, name: 'crumb-cal', title: 'Crumb Event Title',
                       start_date: '2015-12-01', end_date: '2015-12-25', created_by: owner, updated_by: owner)
      end
      let!(:article) do
        create(:item, advent_calendar_item: create(:advent_calendar_item, event: crumb_event, user: owner,
                                                                          date: 2),
                      title: 'Crumb Article Title', body: 'Crumb article body')
      end

      # Returns the breadcrumb event element of the rendered page.
      #
      # @return [Capybara::Node::Element] the breadcrumb event element
      def breadcrumb_event
        Capybara.string(response.body).find('.breadcrumb-event')
      end

      it 'shows TOP / board name / event name in order', :aggregate_failures do
        sign_in owner
        get :show, params: { id: article.id }
        body = response.body
        expect(body.index('TOP')).to be < body.index('Crumb Board Name')
        expect(body.index('Crumb Board Name')).to be < body.index('Crumb Event Title')
      end

      it 'links the event name to the board-scoped calendar page', :aggregate_failures do
        sign_in owner
        get :show, params: { id: article.id }
        expect(breadcrumb_event[:href]).to eq "/boards/#{board.board_id}/events/crumb-cal"
        expect(breadcrumb_event.text).to eq 'Crumb Event Title'
      end

      it 'shows the event name to a guest', :aggregate_failures do
        sign_out user
        get :show, params: { id: article.id }
        expect(response).to render_template :show
        expect(breadcrumb_event[:href]).to eq "/boards/#{board.board_id}/events/crumb-cal"
      end
    end

    context 'when the article is on a top board event' do
      it 'shows TOP / event name without a board name link', :aggregate_failures do
        get :show, params: { id: advent_calendar_item.item.id }
        menu = Capybara.string(response.body).find('nav#top-menu')
        expect(menu.find('.breadcrumb-event')[:href]).to eq '/events/test'
        expect(menu).to have_link('TOP', href: '/')
        expect(menu).to have_no_css('a[href*="/boards/"]')
      end
    end

    context 'when the article cannot be seen' do
      let(:owner) { create(:user) }
      let(:board) { create(:board, :private_user, owner: owner, name: 'Secret Board Name') }
      let(:secret_event) do
        create(:event, board: board, name: 'secret-cal', title: 'Secret Calendar',
                       start_date: '2015-12-01', end_date: '2015-12-25', created_by: owner, updated_by: owner)
      end
      let!(:article) do
        create(:item, advent_calendar_item: create(:advent_calendar_item, event: secret_event, user: owner,
                                                                          date: 2),
                      title: 'Secret Article Title')
      end

      before { sign_out user }

      it 'hides the event and board names for a missing article', :aggregate_failures do
        get :show, params: { id: Item.maximum(:id).to_i + 1 }
        expect(response).to have_http_status(:not_found)
        expect(response.body).not_to include('Secret Board Name', 'Secret Calendar', 'Secret Article Title')
        expect(Capybara.string(response.body)).to have_no_css('.breadcrumb-event')
      end

      it 'hides the event and board names for a hidden article', :aggregate_failures do
        get :show, params: { id: article.id }
        expect(response).to have_http_status(:not_found)
        expect(response.body).not_to include('Secret Board Name', 'Secret Calendar', 'Secret Article Title')
        expect(Capybara.string(response.body)).to have_no_css('.breadcrumb-event')
      end
    end

    context 'when writing an article on a user board event' do
      let(:owner) { create(:user) }
      let(:board) { create(:board, :public_user, owner: owner, name: 'Crumb Board Name') }
      let(:crumb_event) do
        create(:event, board: board, name: 'crumb-new', title: 'Crumb Event Title',
                       start_date: '2015-12-01', end_date: '2015-12-25', created_by: owner, updated_by: owner)
      end
      let!(:article) do
        create(:item, advent_calendar_item: create(:advent_calendar_item, event: crumb_event, user: owner,
                                                                          date: 6),
                      title: 'Crumb Article Title', body: 'Crumb article body')
      end

      before { sign_in owner }

      # Returns the author's empty slot on the event, creating it once per example.
      #
      # @return [AdventCalendarItem]
      def empty_slot
        @empty_slot ||= create(:advent_calendar_item, event: crumb_event, user: owner, date: 7)
      end

      it 'shows the event name on the new article form', :aggregate_failures do
        get :new, params: { id: empty_slot.id }
        expect(response).to have_http_status(:success)
        expect(Capybara.string(response.body)).to have_css('.breadcrumb-event', text: 'Crumb Event Title')
      end

      it 'shows the event name when the article creation fails', :aggregate_failures do
        allow_any_instance_of(Item).to receive(:save).and_return(false)
        post :create, params: { item: { title: 'x', body: 'y', advent_calendar_item_id: empty_slot.id } }
        expect(response).to have_http_status(:unprocessable_content)
        expect(Capybara.string(response.body)).to have_css('.breadcrumb-event', text: 'Crumb Event Title')
      end

      it 'shows the event name on the edit form', :aggregate_failures do
        get :edit, params: { id: article.id }
        expect(response).to have_http_status(:success)
        expect(Capybara.string(response.body)).to have_css('.breadcrumb-event', text: 'Crumb Event Title')
      end

      it 'shows the event name when the article update fails', :aggregate_failures do
        allow_any_instance_of(Item).to receive(:save).and_return(false)
        patch :update, params: { id: article.id, item: { title: 'broken', body: 'x' } }
        expect(response).to have_http_status(:unprocessable_content)
        expect(Capybara.string(response.body)).to have_css('.breadcrumb-event', text: 'Crumb Event Title')
      end
    end
  end
end
