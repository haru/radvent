# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AdventCalendarItemsController do
  let(:user) { create(:user, admin: false) }

  before do
    Item.destroy_all
    AdventCalendarItem.destroy_all
    Event.destroy_all
    User.destroy_all
    sign_in user
  end

  describe 'GET #show' do
    it 'assigns the requested advent_calendar_item to @advent_calendar_item' do
      advent_calendar_item = create(:advent_calendar_item, user: user)
      get :show, params: { id: advent_calendar_item }
      expect(assigns(:advent_calendar_item)).to eq advent_calendar_item
    end

    it 'renders the :show template' do
      advent_calendar_item = create(:advent_calendar_item)
      get :show, params: { id: advent_calendar_item }
      expect(response).to render_template :show
    end
  end

  describe 'GET #show on a private board' do
    render_views

    let(:owner) { create(:user) }
    let(:author) { owner }
    let(:board) { create(:board, :private_user, owner: owner, name: 'Secret Board Name') }
    let(:private_event) do
      create(:event, board: board, name: 'secret-cal', title: 'Secret Calendar Title',
                     start_date: '2015-12-01', end_date: '2015-12-25', created_by: owner, updated_by: owner)
    end
    let!(:private_aci) do
      create(:advent_calendar_item, event: private_event, user: author, user_name: 'Secret Participant',
                                    comment: 'Secret slot comment', date: 3)
    end
    let(:leaked_texts) { ['Secret Board Name', 'Secret Calendar Title', 'Secret Participant', 'Secret slot comment'] }

    shared_examples 'a hidden slot' do
      before { get :show, params: { id: private_aci.id } }

      it 'responds with 404' do
        expect(response).to have_http_status(:not_found)
      end

      it 'renders the not-found page' do
        expect(response).to render_template('errors/notfound')
      end

      it 'does not leak the board, calendar or participant details' do
        expect(response.body).not_to include(*leaked_texts)
      end
    end

    shared_examples 'a readable slot' do
      before { get :show, params: { id: private_aci.id } }

      it 'renders the slot' do
        expect(response).to render_template :show
      end
    end

    context 'when the viewer is a guest' do
      before { sign_out user }

      it_behaves_like 'a hidden slot'
    end

    context 'when the viewer is signed in but not a member' do
      before { sign_in create(:user) }

      it_behaves_like 'a hidden slot'
    end

    context 'when the viewer registered the slot but is no longer a member' do
      let(:author) { create(:user) }

      before do
        create(:board_membership, board: board, user: author).destroy!
        sign_in author
      end

      it_behaves_like 'a hidden slot'
    end

    context 'when the board is public and the viewer is a guest' do
      let(:board) { create(:board, :public_user, owner: owner, name: 'Secret Board Name') }

      before { sign_out user }

      it_behaves_like 'a readable slot'
    end

    context 'when the board is protected and the viewer is a guest' do
      let(:board) { create(:board, :protected_user, owner: owner, name: 'Secret Board Name') }

      before { sign_out user }

      it_behaves_like 'a readable slot'
    end

    context 'when the viewer is the board owner' do
      before { sign_in owner }

      it_behaves_like 'a readable slot'
    end

    context 'when the viewer is a board member' do
      before do
        member = create(:user)
        create(:board_membership, board: board, user: member)
        sign_in member
      end

      it_behaves_like 'a readable slot'
    end

    context 'when the viewer is a system admin' do
      before { sign_in create(:user, admin: true) }

      it_behaves_like 'a readable slot'
    end

    context 'when the slot does not exist' do
      before do
        sign_out user
        get :show, params: { id: AdventCalendarItem.maximum(:id) + 1 }
      end

      it 'renders the not-found page' do
        expect(response).to render_template('errors/notfound')
      end

      it 'does not mention the board name' do
        expect(response.body).not_to include('Secret Board Name')
      end
    end
  end

  describe 'GET #new' do
    let!(:new_event) do
      create(:event, name: 'aci-new-top', title: 'Aci New Top', start_date: '2015-12-01',
                     end_date: '2015-12-25')
    end

    it 'assigns a new advent_calendar_item to @advent_calendar_item' do
      get :new, params: { date: 1, event_id: new_event.id }
      expect(assigns(:advent_calendar_item)).to be_a_new(AdventCalendarItem)
    end

    it 'assigns the requested date to @advent_calendar_item.date' do
      get :new, params: { date: 1, event_id: new_event.id }
      expect(assigns(:advent_calendar_item).date).to eq 1
    end

    it 'renders the :new template' do
      get :new, params: { date: 1, event_id: new_event.id }
      expect(response).to render_template :new
    end
  end

  describe 'GET #edit' do
    it 'assigns the requested advent_calendar_item to @advent_calendar_item' do
      advent_calendar_item = create(:advent_calendar_item)
      get :edit, params: { id: advent_calendar_item }
      expect(assigns(:advent_calendar_item)).to eq advent_calendar_item
    end

    it 'renders the :edit template' do
      advent_calendar_item = create(:advent_calendar_item, user: user)
      get :edit, params: { id: advent_calendar_item }
      expect(response).to render_template :edit
    end
  end

  describe 'POST #create' do
    it 'saves the new advent_calendar_item in the database' do
      event = create(:event)
      params = { advent_calendar_item: build(:advent_calendar_item, event: event).attributes }
      expect { post :create, params: params }.to change(AdventCalendarItem, :count).by(1)
    end

    it 'redirects to advent_calendar_items#show' do
      event = create(:event)
      params = { advent_calendar_item: build(:advent_calendar_item, event: event).attributes }
      post :create, params: params
      expect(response).to redirect_to advent_calendar_item_path(id: AdventCalendarItem.first.id)
    end
  end

  describe 'PATCH #update' do
    let(:advent_calendar_item) { create(:advent_calendar_item, user: user) }

    it 'locates the requested @advent_calendar_item' do
      patch :update, params: { id: advent_calendar_item,
                               advent_calendar_item: attributes_for(:advent_calendar_item) }
      expect(assigns(:advent_calendar_item)).to eq(advent_calendar_item)
    end

    context 'when changing attributes' do
      before do
        patch :update, params: {
          id: advent_calendar_item,
          advent_calendar_item: attributes_for(:advent_calendar_item,
                                               user_name: 'user_name_updated', comment: 'comment_updated')
        }
        advent_calendar_item.reload
      end

      it 'updates user_name' do
        expect(advent_calendar_item.user_name).to eq('user_name_updated')
      end

      it 'updates comment' do
        expect(advent_calendar_item.comment).to eq('comment_updated')
      end
    end

    it 'renders the :edit if the advent_calendar_item is not updated' do
      allow_any_instance_of(AdventCalendarItem).to receive(:save).and_return(false)
      patch :update, params: { id: advent_calendar_item,
                               advent_calendar_item: attributes_for(:advent_calendar_item) }
      expect(response).to render_template :edit
    end

    it 'redirects to advent_calendar_item#show if the advent_calendar_item is updated' do
      patch :update, params: { id: advent_calendar_item,
                               advent_calendar_item: attributes_for(:advent_calendar_item) }
      expect(response).to redirect_to advent_calendar_item_path(advent_calendar_item)
    end
  end

  describe 'slot creation authorization' do
    let(:event_owner) { create(:user) }
    let(:outsider) { create(:user) }
    let(:top_board) { create(:board, :top) }
    let(:public_board) { create(:board, :public_user, owner: event_owner) }
    let(:protected_board) { create(:board, :protected_user, owner: event_owner) }
    let(:private_board) { create(:board, :private_user, owner: event_owner) }

    # Creates an event on the given board with a unique name.
    #
    # @param board [Board] the board the event belongs to
    # @param name [String] the unique event name, also used as the title
    # @return [Event] the created event
    def event_on(board, name)
      create(:event, board: board, name: name, title: name, start_date: '2015-12-01',
                     end_date: '2015-12-25', created_by: event_owner, updated_by: event_owner)
    end

    # Returns the TOP board event, creating it once per example.
    #
    # @return [Event]
    def top_event
      @top_event ||= event_on(top_board, 'join-top')
    end

    # Returns the public board event, creating it once per example.
    #
    # @return [Event]
    def public_event
      @public_event ||= event_on(public_board, 'join-public')
    end

    # Returns the protected board event, creating it once per example.
    #
    # @return [Event]
    def protected_event
      @protected_event ||= event_on(protected_board, 'join-protected')
    end

    # Returns the private board event, creating it once per example.
    #
    # @return [Event]
    def private_event
      @private_event ||= event_on(private_board, 'join-private')
    end

    # Posts a slot creation request for the given event.
    #
    # @param event_id [Integer] the event id sent in the request
    # @param date [Integer] the requested calendar date
    # @return [void]
    def create_slot(event_id, date: 5)
      post :create, params: { advent_calendar_item: { user_name: 'participant', comment: 'join',
                                                      date: date, event_id: event_id } }
    end

    describe 'GET #new' do
      it 'returns 404 for an event on a board the user cannot see' do
        sign_in outsider
        get :new, params: { event_id: private_event.id, date: 5 }
        expect(response).to have_http_status(:not_found)
      end

      it 'returns 404 for a non-existent event' do
        sign_in outsider
        get :new, params: { event_id: Event.maximum(:id).to_i + 1, date: 5 }
        expect(response).to have_http_status(:not_found)
      end

      it 'returns 403 for an event the user cannot join' do
        sign_in outsider
        get :new, params: { event_id: protected_event.id, date: 5 }
        expect(response).to have_http_status(:forbidden)
      end

      it 'returns success for a joinable event' do
        sign_in outsider
        get :new, params: { event_id: top_event.id, date: 5 }
        expect(response).to have_http_status(:success)
      end

      it 'redirects to the sign-in page when not signed in' do
        sign_out user
        get :new, params: { event_id: top_event.id, date: 5 }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    describe 'POST #create' do
      it 'returns 404 and creates nothing for an event on an invisible board', :aggregate_failures do
        sign_in outsider
        expect { create_slot(private_event.id) }.not_to change(AdventCalendarItem, :count)
        expect(response).to have_http_status(:not_found)
      end

      it 'returns 404 and creates nothing for a non-existent event', :aggregate_failures do
        sign_in outsider
        expect { create_slot(Event.maximum(:id).to_i + 1) }.not_to change(AdventCalendarItem, :count)
        expect(response).to have_http_status(:not_found)
      end

      it 'returns 403 and creates nothing for an event the user cannot join', :aggregate_failures do
        sign_in outsider
        expect { create_slot(protected_event.id) }.not_to change(AdventCalendarItem, :count)
        expect(response).to have_http_status(:forbidden)
      end

      it 'creates a slot on a TOP board event for a logged-in user', :aggregate_failures do
        sign_in outsider
        expect { create_slot(top_event.id) }.to change(AdventCalendarItem, :count).by(1)
        expect(response).to redirect_to(advent_calendar_item_path(id: AdventCalendarItem.last.id))
      end

      it 'creates a slot on a public board event for a logged-in user', :aggregate_failures do
        sign_in outsider
        expect { create_slot(public_event.id) }.to change(AdventCalendarItem, :count).by(1)
        expect(response).to redirect_to(advent_calendar_item_path(id: AdventCalendarItem.last.id))
      end

      it 'creates a slot on a protected board event for the owner' do
        sign_in event_owner
        expect { create_slot(protected_event.id) }.to change(AdventCalendarItem, :count).by(1)
      end

      it 'creates a slot on a private board event for a member' do
        member = create(:user)
        create(:board_membership, board: private_board, user: member)
        sign_in member
        expect { create_slot(private_event.id) }.to change(AdventCalendarItem, :count).by(1)
      end

      it 'creates a slot on a private board event for admin' do
        sign_in create(:user, admin: true)
        expect { create_slot(private_event.id) }.to change(AdventCalendarItem, :count).by(1)
      end

      it 'redirects to the sign-in page when not signed in' do
        sign_out user
        create_slot(top_event.id)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    describe 'POST #create with a conflicting top-level event_id' do
      it 'authorizes only advent_calendar_item[event_id]', :aggregate_failures do
        sign_in outsider
        params = { user_name: 'x', comment: 'c', date: 3, event_id: protected_event.id }
        expect { post :create, params: { event_id: top_event.id, advent_calendar_item: params } }
          .not_to change(AdventCalendarItem, :count)
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe 'PATCH #update keeps the slot in its event' do
      let(:slot) { create(:advent_calendar_item, event: top_event, user: event_owner, date: 3) }

      before { sign_in event_owner }

      it 'keeps the slot in the original event when another event is given', :aggregate_failures do
        patch :update, params: { id: slot, advent_calendar_item: { comment: 'comment_updated',
                                                                   event_id: private_event.id } }
        expect(slot.reload.event_id).to eq top_event.id
        expect(slot.comment).to eq 'comment_updated'
        expect(response).to redirect_to advent_calendar_item_path(slot)
      end
    end
  end

  describe 'date duplication' do
    render_views

    let(:taken_by) { create(:user) }
    let(:event) do
      create(:event, name: 'dup-cal', title: 'Dup Calendar', start_date: '2015-12-01',
                     end_date: '2015-12-25')
    end
    let(:taken_message) do
      key = 'activerecord.errors.models.advent_calendar_item.attributes.date.taken'
      "#{AdventCalendarItem.human_attribute_name(:date)}#{I18n.t(key)}"
    end

    before do
      sign_in user
      create(:advent_calendar_item, event: event, user: taken_by, date: 5)
    end

    # Posts a slot creation request for the given event and date.
    #
    # @param event_id [Integer] the event id sent in the request
    # @param date [Integer] the requested calendar date
    # @return [void]
    def post_dup_slot(event_id, date)
      post :create, params: { advent_calendar_item: { user_name: user.name, comment: 'dup',
                                                      date: date, event_id: event_id } }
    end

    it 'rejects create on a taken date, shows the message and renders new', :aggregate_failures do
      expect { post_dup_slot(event.id, 5) }.not_to change(AdventCalendarItem, :count)
      expect(response).to have_http_status(:unprocessable_content)
      expect(response).to render_template :new
      expect(response.body).to include(taken_message)
    end

    it 'rejects update to a taken date, shows the message and renders edit', :aggregate_failures do
      slot = create(:advent_calendar_item, event: event, user: user, date: 7)
      patch :update, params: { id: slot, advent_calendar_item: { comment: 'try move', date: 5 } }
      expect(slot.reload.date).to eq 7
      expect(response).to have_http_status(:unprocessable_content).and render_template(:edit)
      expect(response.body).to include(taken_message)
    end

    it 'rejects create without a date and renders new with the event id kept', :aggregate_failures do
      expect { post_dup_slot(event.id, '') }.not_to change(AdventCalendarItem, :count)
      expect(response).to have_http_status(:unprocessable_content)
      hidden_event = response.body[/<input[^>]*name="advent_calendar_item\[event_id\]"[^>]*>/]
      expect(hidden_event).to include(%(value="#{event.id}"))
    end

    it 'allows create on the same date in another event' do
      other_event = create(:event, name: 'dup-other-cal', title: 'Dup Other Calendar',
                                   start_date: '2015-12-01', end_date: '2015-12-25')
      expect { post_dup_slot(other_event.id, 5) }.to change(AdventCalendarItem, :count).by(1)
    end

    it 'allows updating a pre-existing duplicate without changing the date', :aggregate_failures do
      duplicate = AdventCalendarItem.new(event: event, date: 8, user: user, user_name: user.name)
      duplicate.save(validate: false)
      patch :update, params: { id: duplicate.id, advent_calendar_item: { comment: 'updated comment' } }
      expect(response).to redirect_to advent_calendar_item_path(duplicate.reload)
      expect(duplicate.reload.comment).to eq 'updated comment'
    end
  end
end
