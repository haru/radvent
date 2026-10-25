# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EventsController do
  let(:user) { create(:user, admin: true) }
  let(:event) do
    create(:event, name: 'hogehoge', title: 'foobar', start_date: '2016-12-01', end_date: '2016-12-30',
                   created_by: user, updated_by: user)
  end

  before do
    sign_in user
    event
  end

  describe 'GET #new' do
    it 'returns http success' do
      get :new
      expect(response).to have_http_status(:success)
    end

    it 'assigns @event as a new Event' do
      get :new
      expect(assigns(:event)).to be_a(Event)
    end

    it 'assigns @event as a new record' do
      get :new
      expect(assigns(:event)).to be_new_record
    end
  end

  describe 'POST #create' do
    it 'returns http success' do
      post :create,
           params: { event: { title: 'test', start_date: '2017-12-01', end_date: '2017-12-25', name: 'aaa',
                              description: 'description' } }
      expect(response).to have_http_status(:redirect)
    end

    it 'returns 403 if user is not admin' do
      sign_in create(:user)
      post :create,
           params: { event: { title: 'test2', start_date: '2017-12-01', end_date: '2017-12-25', name: 'bbb',
                              description: 'description' } }
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'PUT #update' do
    it 'returns http success' do
      put :update,
          params: { name: event.name,
                    event: { title: 'test', start_date: '2017-12-01', end_date: '2017-12-25', name: 'aaa',
                             description: 'description' } }
      expect(response).to have_http_status(:see_other)
    end

    it 'redirects to event view after successful update' do
      put :update,
          params: { name: event.name,
                    event: { title: 'updated', start_date: '2017-12-01', end_date: '2017-12-25', name: 'aaa',
                             description: 'description' } }
      expect(response).to redirect_to(show_event_path('aaa'))
    end
  end

  describe 'check_edit_permission' do
    let(:event_owner) { create(:user) }
    let(:admin_user) { create(:user, admin: true) }
    let(:other_user) { create(:user) }
    let(:owned_event) do
      create(:event, name: 'owned-event', title: 'Owned Event', start_date: '2016-12-01', end_date: '2016-12-25',
                     created_by: event_owner, updated_by: event_owner)
    end

    before do
      owned_event
    end

    context 'when user is event owner' do
      before { sign_in event_owner }

      it 'allows access to edit action' do
        get :edit, params: { name: owned_event.name }
        expect(response).not_to have_http_status(:forbidden)
      end

      it 'allows access to update action' do
        put :update, params: { name: owned_event.name, event: { title: 'test' } }
        expect(response).not_to have_http_status(:forbidden)
      end

      it 'allows access to destroy action' do
        delete :destroy, params: { name: owned_event.name }
        expect(response).not_to have_http_status(:forbidden)
      end
    end

    context 'when user is admin' do
      before { sign_in admin_user }

      it 'allows access to edit action' do
        get :edit, params: { name: owned_event.name }
        expect(response).not_to have_http_status(:forbidden)
      end

      it 'allows access to update action' do
        put :update, params: { name: owned_event.name, event: { title: 'test' } }
        expect(response).not_to have_http_status(:forbidden)
      end

      it 'allows access to destroy action' do
        delete :destroy, params: { name: owned_event.name }
        expect(response).not_to have_http_status(:forbidden)
      end
    end

    context 'when user is not event owner and not admin' do
      before { sign_in other_user }

      it 'denies access to edit action' do
        get :edit, params: { name: owned_event.name }
        expect(response).to have_http_status(:forbidden)
      end

      it 'denies access to update action' do
        put :update, params: { name: owned_event.name, event: { title: 'test' } }
        expect(response).to have_http_status(:forbidden)
      end

      it 'denies access to destroy action' do
        delete :destroy, params: { name: owned_event.name }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'returns http success' do
      delete :destroy, params: { name: event.name }
      expect(response).to have_http_status(:redirect)
    end

    it 'redirects to board page after successful destroy' do
      delete :destroy, params: { name: event.name }
      expect(response).to redirect_to(root_path)
    end
  end

  describe 'GET #show' do
    it 'returns http success' do
      get :show, params: { name: event.name }
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET #show on a board with restricted visibility' do
    render_views

    let(:owner) { create(:user) }
    let(:board) { create(:board, :private_user, owner: owner, name: 'Secret Board Name') }
    let(:secret_event) do
      create(:event, board: board, name: 'secret-cal', title: 'Secret Calendar Title',
                     description: 'Secret event description', start_date: '2015-12-01', end_date: '2015-12-25',
                     created_by: owner, updated_by: owner)
    end
    let(:leaked_texts) do
      ['Secret Board Name', 'Secret Calendar Title', 'Secret event description', 'Secret Participant',
       'Secret slot comment']
    end

    before do
      create(:advent_calendar_item, event: secret_event, user: owner, user_name: 'Secret Participant',
                                    comment: 'Secret slot comment', date: 3)
    end

    shared_examples 'a hidden calendar' do
      before { get :show, params: { board_board_id: board.board_id, name: secret_event.name } }

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

    shared_examples 'a readable calendar' do
      before { get :show, params: { board_board_id: board.board_id, name: secret_event.name } }

      it 'renders the calendar' do
        expect(response).to render_template :show
      end
    end

    context 'when the board is private and the viewer is a guest' do
      before { sign_out user }

      it_behaves_like 'a hidden calendar'
    end

    context 'when the board is private and the viewer is signed in but not a member' do
      before { sign_in create(:user) }

      it_behaves_like 'a hidden calendar'
    end

    context 'when the board is private and the viewer is the board owner' do
      before { sign_in owner }

      it_behaves_like 'a readable calendar'
    end

    context 'when the board is private and the viewer is a board member' do
      before do
        member = create(:user)
        create(:board_membership, board: board, user: member)
        sign_in member
      end

      it_behaves_like 'a readable calendar'
    end

    context 'when the board is private and the viewer is a system admin' do
      before { sign_in create(:user, admin: true) }

      it_behaves_like 'a readable calendar'
    end

    context 'when the board is public and the viewer is a guest' do
      let(:board) { create(:board, :public_user, owner: owner, name: 'Secret Board Name') }

      before { sign_out user }

      it_behaves_like 'a readable calendar'
    end

    context 'when the board is protected and the viewer is a guest' do
      let(:board) { create(:board, :protected_user, owner: owner, name: 'Secret Board Name') }

      before { sign_out user }

      it_behaves_like 'a readable calendar'
    end

    context 'when the event does not exist' do
      before do
        sign_out user
        get :show, params: { name: 'no-such-event' }
      end

      it 'renders the not-found page' do
        expect(response).to render_template('errors/notfound')
      end

      it 'does not mention the board name' do
        expect(response.body).not_to include('Secret Board Name')
      end
    end
  end

  describe 'POST #create failure' do
    it 'renders new with unprocessable content on invalid event' do
      post :create, params: { event: { title: '', start_date: '', end_date: '', name: '', description: '' } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe 'PUT #update failure' do
    it 'renders edit with unprocessable content on invalid update' do
      put :update, params: { name: event.name, event: { title: '' } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe 'POST #create on UserBoard' do
    let(:board_owner) { create(:user) }
    let(:public_board) { create(:board, :public_user, owner: board_owner) }
    let(:protected_board) { create(:board, :protected_user, owner: board_owner) }
    let(:non_member) { create(:user) }

    context 'when user is authenticated on a Public Board' do
      before { sign_in non_member }

      it 'allows authenticated non-member to create event' do
        post :create, params: {
          event: { title: 'public-event', start_date: '2017-12-01', end_date: '2017-12-25',
                   name: 'public-evt', description: 'desc', board_id: public_board.id }
        }
        expect(response).to have_http_status(:redirect)
      end
    end

    context 'when user is not a member of a Protected Board' do
      before { sign_in non_member }

      it 'returns 403' do
        post :create, params: {
          event: { title: 'protected-event', start_date: '2017-12-01', end_date: '2017-12-25',
                   name: 'protected-evt', description: 'desc', board_id: protected_board.id }
        }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'event creation authorization' do
    let(:board_owner) { create(:user) }
    let(:other_user) { create(:user) }
    let(:public_board) { create(:board, :public_user, owner: board_owner) }
    let(:protected_board) { create(:board, :protected_user, owner: board_owner) }
    let(:private_board) { create(:board, :private_user, owner: board_owner) }
    let(:own_board) { create(:board, :public_user, owner: other_user) }
    let(:top_board) { Board.find_by!(board_type: :top) }

    before do
      public_board
      protected_board
      private_board
      own_board
    end

    # Extracts the hidden input for the target board from the rendered form.
    #
    # @return [String, nil] the matching input tag, or nil when it is not rendered
    def event_board_hidden_input
      response.body[/<input[^>]*name="event\[board_id\]"[^>]*>/]
    end

    # Posts an event creation request.
    #
    # @param board_id [Object] the event[board_id] value sent in the request
    # @param name [String] the unique event name
    # @param top_level_board_id [Object, nil] the top-level board_id sent beside the event payload
    # @param title [String] the event title
    # @return [void]
    def post_event(board_id, name, top_level_board_id: nil, title: 'new event')
      params = { event: { title: title, start_date: '2017-12-01', end_date: '2017-12-25',
                          name: name, description: 'desc', board_id: board_id } }
      params[:board_id] = top_level_board_id if top_level_board_id
      post :create, params: params
    end

    describe 'GET #new' do
      render_views

      it 'returns success for admin without board_id' do
        get :new
        expect(response).to have_http_status(:success)
      end

      it 'returns 403 without board_id (TOP) for a non-admin' do
        sign_in other_user
        get :new
        expect(response).to have_http_status(:forbidden)
      end

      it 'embeds the board id for a public board', :aggregate_failures do
        sign_in other_user
        get :new, params: { board_id: public_board.id }
        expect(response).to have_http_status(:success)
        expect(event_board_hidden_input).to include(%(value="#{public_board.id}"))
      end

      it 'embeds the board id for the own board', :aggregate_failures do
        sign_in other_user
        get :new, params: { board_id: own_board.id }
        expect(response).to have_http_status(:success)
        expect(event_board_hidden_input).to include(%(value="#{own_board.id}"))
      end

      it 'returns 403 for a protected board the user is not a member of' do
        sign_in other_user
        get :new, params: { board_id: protected_board.id }
        expect(response).to have_http_status(:forbidden)
      end

      it 'returns 404 for a private board the user is not a member of' do
        sign_in other_user
        get :new, params: { board_id: private_board.id }
        expect(response).to have_http_status(:not_found)
      end

      it 'returns 404 for a non-existent board id' do
        sign_in other_user
        get :new, params: { board_id: Board.maximum(:id).to_i + 1 }
        expect(response).to have_http_status(:not_found)
      end
    end

    describe 'POST #create' do
      it 'returns 403 and creates nothing when event[board_id] is empty', :aggregate_failures do
        sign_in other_user
        expect { post_event('', 'auth-evt-empty', top_level_board_id: own_board.id) }
          .not_to change(Event, :count)
        expect(response).to have_http_status(:forbidden)
      end

      it 'returns 404 and creates nothing when event[board_id] is an invisible private board',
         :aggregate_failures do
        sign_in other_user
        expect { post_event(private_board.id, 'auth-evt-private', top_level_board_id: own_board.id) }
          .not_to change(Event, :count)
        expect(response).to have_http_status(:not_found)
      end

      it 'returns 404 and creates nothing when event[board_id] does not exist', :aggregate_failures do
        sign_in other_user
        expect { post_event(Board.maximum(:id).to_i + 1, 'auth-evt-none', top_level_board_id: own_board.id) }
          .not_to change(Event, :count)
        expect(response).to have_http_status(:not_found)
      end

      it 'returns 403 and creates nothing for a protected board the user is not a member of',
         :aggregate_failures do
        sign_in other_user
        expect { post_event(protected_board.id, 'auth-evt-protected') }.not_to change(Event, :count)
        expect(response).to have_http_status(:forbidden)
      end

      it 'creates the event and redirects to the board page for the own board', :aggregate_failures do
        sign_in other_user
        expect { post_event(own_board.id, 'auth-evt-own') }.to change(Event, :count).by(1)
        expect(response).to redirect_to(board_path(own_board.board_id))
        expect(Event.last.board).to eq own_board
      end

      it 'creates the event on event[board_id] even when a top-level board_id points elsewhere',
         :aggregate_failures do
        sign_in other_user
        expect { post_event(own_board.id, 'auth-evt-mismatch', top_level_board_id: top_board.id) }
          .to change(Event, :count).by(1)
        expect(Event.last.board).to eq own_board
      end

      it 'creates the event on a private board for a board member', :aggregate_failures do
        create(:board_membership, board: private_board, user: other_user)
        sign_in other_user
        expect { post_event(private_board.id, 'auth-evt-member') }.to change(Event, :count).by(1)
        expect(Event.last.board).to eq private_board
      end

      it 'creates the event on a protected board for a board member', :aggregate_failures do
        create(:board_membership, board: protected_board, user: other_user)
        sign_in other_user
        expect { post_event(protected_board.id, 'auth-evt-protected-member') }.to change(Event, :count).by(1)
        expect(Event.last.board).to eq protected_board
      end

      it 'returns 403 and creates nothing for a guest', :aggregate_failures do
        sign_out user
        expect { post_event(public_board.id, 'auth-evt-guest') }.not_to change(Event, :count)
        expect(response).to have_http_status(:forbidden)
      end

      it 'creates the event on the TOP board and redirects to root when board_id is empty',
         :aggregate_failures do
        expect { post_event('', 'auth-evt-top-empty') }.to change(Event, :count).by(1)
        expect(response).to redirect_to(root_path)
        expect(Event.last.board).to eq top_board
      end

      it 'creates the event on the TOP board and redirects to root when the TOP board is given',
         :aggregate_failures do
        expect { post_event(top_board.id, 'auth-evt-top-given') }.to change(Event, :count).by(1)
        expect(response).to redirect_to(root_path)
        expect(Event.last.board).to eq top_board
      end
    end

    describe 'hidden board name' do
      render_views

      it 'is not rendered in the 404 page of GET #new', :aggregate_failures do
        sign_in other_user
        get :new, params: { board_id: private_board.id }
        expect(response).to have_http_status(:not_found)
        expect(response.body).not_to include(private_board.name)
      end

      it 'is not rendered in the 404 page of POST #create', :aggregate_failures do
        sign_in other_user
        post_event(private_board.id, 'auth-evt-leak')
        expect(response).to have_http_status(:not_found)
        expect(response.body).not_to include(private_board.name)
      end
    end

    describe 'POST #create failure' do
      render_views

      it 'keeps the same board id in the hidden field when rendering new again', :aggregate_failures do
        sign_in other_user
        post_event(own_board.id, 'auth-evt-fail', title: '')
        expect(response).to have_http_status(:unprocessable_content)
        expect(event_board_hidden_input).to include(%(value="#{own_board.id}"))
      end
    end
  end

  describe 'breadcrumb trail' do
    render_views

    let(:crumb_event) do
      create(:event, name: 'crumb-ev', title: 'Crumb Event Title', start_date: '2015-12-01',
                     end_date: '2015-12-25', created_by: user, updated_by: user)
    end

    # Returns the breadcrumb event element of the last rendered page.
    #
    # @return [Capybara::Node::Element] the breadcrumb event element
    def breadcrumb_event
      Capybara.string(response.body).find('.breadcrumb-event')
    end

    it 'marks the event as the current location on the calendar page', :aggregate_failures do
      get :show, params: { name: crumb_event.name }
      expect(breadcrumb_event.tag_name).to eq 'span'
      expect(breadcrumb_event[:'aria-current']).to eq 'page'
      expect(breadcrumb_event.text).to eq 'Crumb Event Title'
    end

    it 'links the event name to the calendar page on the edit form', :aggregate_failures do
      get :edit, params: { name: crumb_event.name }
      expect(breadcrumb_event.tag_name).to eq 'a'
      expect(breadcrumb_event[:href]).to eq '/events/crumb-ev'
      expect(breadcrumb_event.text).to eq 'Crumb Event Title'
    end

    it 'keeps the persisted title and persisted name link when the update fails',
       :aggregate_failures do
      put :update, params: { name: crumb_event.name,
                             event: { title: '', name: 'renamed-crumb', description: 'x' } }
      expect(response).to have_http_status(:unprocessable_content)
      expect(breadcrumb_event.text).to eq 'Crumb Event Title'
      expect(breadcrumb_event[:href]).to eq '/events/crumb-ev'
    end

    it 'shows no event name on new and on a failed create', :aggregate_failures do
      get :new
      expect(response).to have_http_status(:success)
      expect(Capybara.string(response.body)).to have_no_css('.breadcrumb-event')
    end

    it 'shows no event name when the create fails and renders new again', :aggregate_failures do
      post :create, params: { event: { title: '', start_date: '', end_date: '', name: '', description: '' } }
      expect(response).to have_http_status(:unprocessable_content)
      expect(Capybara.string(response.body)).to have_no_css('.breadcrumb-event')
    end

    it 'shows no event name on the 404 page of show', :aggregate_failures do
      sign_out user
      get :show, params: { name: 'no-such-crumb' }
      expect(response).to have_http_status(:not_found)
      expect(Capybara.string(response.body)).to have_no_css('.breadcrumb-event')
    end
  end
end
