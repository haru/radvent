# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BoardMembershipsController do
  let(:owner) { create(:user) }
  let(:other_user) { create(:user) }
  let(:admin) { create(:user, admin: true) }
  let(:board) { create(:board, :protected_user, owner: owner) }

  describe 'GET #index' do
    context 'when not authenticated' do
      it 'redirects to sign in' do
        get :index, params: { board_board_id: board.board_id }
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'tells the guest to sign in or sign up' do
        get :index, params: { board_board_id: board.board_id }
        expect(flash[:alert]).to eq I18n.t('devise.failure.unauthenticated')
      end
    end

    context 'when authenticated as non-owner' do
      before { sign_in other_user }

      it 'returns 403' do
        get :index, params: { board_board_id: board.board_id }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when authenticated as owner' do
      render_views
      before { sign_in owner }

      it 'returns http success' do
        get :index, params: { board_board_id: board.board_id }
        expect(response).to have_http_status(:success)
      end

      it 'renders datatable controller on the memberships table' do
        get :index, params: { board_board_id: board.board_id }
        expect(response.body).to include('data-controller="datatable"')
      end
    end

    context 'when authenticated as owner with a member' do
      render_views
      before do
        sign_in owner
        create(:board_membership, board: board, user: other_user)
        get :index, params: { board_board_id: board.board_id }
      end

      let(:row) { Capybara.string(response.body).find('tbody tr', text: other_user.name) }

      it 'shows user and envelope icons next to name and e-mail', :aggregate_failures do
        expect(row).to have_css("td i.fa-user[aria-hidden='true']", count: 1)
        expect(row).to have_css("td i.fa-envelope[aria-hidden='true']", count: 1)
      end

      it 'links back to the board settings page' do
        expect(Capybara.string(response.body)).to have_link(I18n.t('board_memberships.index.back_to_settings'),
                                                            href: edit_board_path(board.board_id))
      end

      it 'names the member in the remove confirmation' do
        confirm = I18n.t('board_memberships.remove_confirm', name: other_user.name)
        expect(row.find('button')['data-turbo-confirm']).to eq confirm
      end

      it 'shows a trash icon together with the remove label', :aggregate_failures do
        expect(row).to have_css("button i.fa-trash[aria-hidden='true']", count: 1)
        expect(row).to have_button(I18n.t('board_memberships.remove'))
      end
    end

    context 'when a member has deleted their account' do
      render_views
      before do
        sign_in owner
        create(:board_membership, board: board, user: other_user)
        other_user.destroy
      end

      it 'lists the row as a deleted user and keeps the remove button', :aggregate_failures do
        get :index, params: { board_board_id: board.board_id }
        expect(response).to have_http_status(:success)
        page = Capybara.string(response.body)
        expect(page).to have_css('td', text: I18n.t('board_memberships.index.deleted_user'))
        expect(page).to have_button(I18n.t('board_memberships.remove'))
      end

      it 'shows the user icon but no envelope icon on the deleted-user row', :aggregate_failures do
        get :index, params: { board_board_id: board.board_id }
        page = Capybara.string(response.body)
        expect(page.find('td', text: I18n.t('board_memberships.index.deleted_user'))).to have_css('i.fa-user')
        expect(page).to have_no_css('i.fa-envelope')
      end

      it 'uses the deleted-user label in the remove confirmation' do
        get :index, params: { board_board_id: board.board_id }
        confirm = I18n.t('board_memberships.remove_confirm', name: I18n.t('board_memberships.index.deleted_user'))
        expect(Capybara.string(response.body).find('tbody tr button')['data-turbo-confirm']).to eq confirm
      end
    end

    context 'when authenticated as admin' do
      before { sign_in admin }

      it 'returns http success' do
        get :index, params: { board_board_id: board.board_id }
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'GET #search' do
    let(:params) { { board_board_id: board.board_id, member_query: 'ab' } }

    context 'when not authenticated' do
      render_views
      before { create(:user, name: 'abby') }

      it 'redirects to sign in' do
        get :search, params: params
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'returns no candidates' do
        get :search, params: params
        expect(response.body).not_to include('abby')
      end
    end

    context 'when the board does not exist' do
      before { sign_in owner }

      it 'returns 404' do
        get :search, params: params.merge(board_board_id: 'no-such-board')
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when authenticated as a user who cannot manage members' do
      render_views
      before do
        create(:user, name: 'abby')
        create(:board_membership, board: board, user: other_user)
      end

      it 'returns 403 to an unrelated user without candidates', :aggregate_failures do
        sign_in create(:user)
        get :search, params: params
        expect(response).to have_http_status(:forbidden)
        expect(response.body).not_to include('abby')
      end

      it 'returns 403 to a plain member', :aggregate_failures do
        sign_in other_user
        get :search, params: params
        expect(response).to have_http_status(:forbidden)
        expect(response.body).not_to include('abby')
      end
    end

    context 'when authenticated as owner' do
      before { sign_in owner }

      it 'returns 204 without a body for an empty query', :aggregate_failures do
        get :search, params: params.merge(member_query: '')
        expect(response).to have_http_status(:no_content)
        expect(response.body).to be_empty
      end

      it 'returns 204 for a one-character query' do
        get :search, params: params.merge(member_query: 'a')
        expect(response).to have_http_status(:no_content)
      end

      it 'ignores surrounding whitespace when counting characters' do
        get :search, params: params.merge(member_query: '  a  ')
        expect(response).to have_http_status(:no_content)
      end

      it 'rejects a query longer than the limit with 400', :aggregate_failures do
        get :search, params: params.merge(member_query: 'a' * (described_class::MAX_QUERY_LENGTH + 1))
        expect(response).to have_http_status(:bad_request)
      end

      it 'rejects a non-string query with 400' do
        get :search, params: params.merge(member_query: %w[ab])
        expect(response).to have_http_status(:bad_request)
      end

      it 'returns 204 when the query is missing' do
        get :search, params: { board_board_id: board.board_id }
        expect(response).to have_http_status(:no_content)
      end

      it 'allows 60 searches a minute and rejects the 61st with 429', :aggregate_failures do
        60.times { get :search, params: params.merge(member_query: 'a') }
        expect(response).to have_http_status(:no_content)
        get :search, params: params.merge(member_query: 'a')
        expect(response).to have_http_status(:too_many_requests)
      end

      it 'counts searches per user' do
        60.times { get :search, params: params.merge(member_query: 'a') }
        sign_in admin
        get :search, params: params.merge(member_query: 'a')
        expect(response).to have_http_status(:no_content)
      end
    end

    context 'when the rate limit is exceeded' do
      render_views

      before do
        sign_in owner
        create(:user, name: 'yamada', email: 'yamada@example.com')
      end

      it 'withholds candidates from the 61st search', :aggregate_failures do
        60.times { get :search, params: params.merge(member_query: 'yamada') }
        get :search, params: params.merge(member_query: 'yamada')
        expect(response).to have_http_status(:too_many_requests)
        expect(response.body).not_to include('yamada@example.com')
      end

      it 'allows searching again after a minute' do
        61.times { get :search, params: params.merge(member_query: 'a') }
        travel 61.seconds
        get :search, params: params.merge(member_query: 'a')
        expect(response).to have_http_status(:no_content)
      end

      it 'shares the counter across boards of the same user' do
        other_board = create(:board, :protected_user, owner: owner)
        60.times { get :search, params: params.merge(member_query: 'a') }
        get :search, params: params.merge(board_board_id: other_board.board_id, member_query: 'a')
        expect(response).to have_http_status(:too_many_requests)
      end
    end

    context 'when requests are rejected by the permission check' do
      it 'does not count them toward the rate limit' do
        sign_in other_user
        61.times { get :search, params: params }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when candidates match' do
      render_views
      let(:page) { Capybara.string(response.body) }

      before { sign_in owner }

      it 'lists name and email of each candidate as options', :aggregate_failures do
        create(:user, name: 'Yamada Taro', email: 'yamada@example.com')
        get :search, params: params.merge(member_query: 'yamada')
        expect(response).to have_http_status(:ok)
        expect(page.find('[role="option"]')).to have_text('Yamada Taro').and have_text('yamada@example.com')
      end

      it 'gives each option the id and label used by the form', :aggregate_failures do
        user = create(:user, name: 'Yamada Taro', email: 'yamada@example.com')
        get :search, params: params.merge(member_query: 'yamada')
        option = page.find('[role="option"]')
        expect(option['data-member-search-user-id']).to eq user.id.to_s
        expect(option['data-member-search-label']).to include('Yamada Taro', 'yamada@example.com')
      end

      it 'finds a user by a part of the email address', :aggregate_failures do
        create(:user, name: 'Someone', email: 'taro.yamada@example.com')
        get :search, params: params.merge(member_query: 'YAMADA@')
        option = page.find('[role="option"]')
        expect(option).to have_text('Someone')
        expect(option).to have_text('taro.yamada@example.com')
      end

      it 'searches from exactly 2 characters', :aggregate_failures do
        create(:user, name: 'Yamada Taro')
        get :search, params: params.merge(member_query: 'ya')
        expect(response).to have_http_status(:ok)
        expect(page).to have_css('[role="option"]', count: 1)
      end

      it 'counts multibyte characters, not bytes' do
        get :search, params: params.merge(member_query: '山')
        expect(response).to have_http_status(:no_content)
      end

      it 'uses the email alone as the label of a user without a name', :aggregate_failures do
        create(:user, email: 'noname@example.com').update_column(:name, nil) # rubocop:disable Rails/SkipsModelValidations
        get :search, params: params.merge(member_query: 'noname@')
        option = page.find('[role="option"]')
        expect(option['data-member-search-label']).to eq 'noname@example.com'
        expect(option).to have_no_css('.member-search-name')
      end

      it 'strips surrounding whitespace from the query' do
        create(:user, name: 'Yamada Taro')
        get :search, params: params.merge(member_query: "  yamada \n")
        expect(page).to have_css('[role="option"]', count: 1)
      end

      it 'forbids caching of the response' do
        create(:user, name: 'Yamada Taro')
        get :search, params: params.merge(member_query: 'yamada')
        expect(response.headers['Cache-Control']).to include('no-store')
      end

      it 'escapes HTML in names', :aggregate_failures do
        create(:user, name: '<b>bold</b>x')
        get :search, params: params.merge(member_query: 'bold')
        expect(response.body).not_to include('<b>bold')
        expect(response.body).to include('&lt;b&gt;bold')
      end

      it 'shows a non-selectable no-results row', :aggregate_failures do
        get :search, params: params.merge(member_query: 'nobody-matches')
        expect(page).to have_text(I18n.t('board_memberships.index.no_results'))
        expect(page).to have_no_css('[role="option"]')
      end

      it 'shows 10 candidates and a refine row for 11 matches', :aggregate_failures do
        11.times { |i| create(:user, name: format('many-%02d', i)) }
        get :search, params: params.merge(member_query: 'many-')
        expect(page).to have_css('[role="option"]', count: 10)
        expect(page).to have_text(I18n.t('board_memberships.index.refine_search'))
      end

      it 'escapes HTML in email addresses' do
        create(:user, name: 'Mailer', email: '"><i>x</i>@example.com')
        get :search, params: params.merge(member_query: '<i>x')
        expect(response.body).not_to include('<i>x</i>')
      end

      it 'does not expose private user columns', :aggregate_failures do
        user = create(:user, name: 'Yamada Taro')
        user.update_columns(reset_password_token: 'secret-reset-token', last_sign_in_ip: '203.0.113.9') # rubocop:disable Rails/SkipsModelValidations
        get :search, params: params.merge(member_query: 'yamada')
        expect(response.body).not_to include(user.encrypted_password, 'secret-reset-token', '203.0.113.9')
      end

      it 'gives an option nothing but its id and label as data', :aggregate_failures do
        create(:user, name: 'Yamada Taro')
        get :search, params: params.merge(member_query: 'yamada')
        data = page.find('[role="option"]').native.attributes.keys.grep(/\Adata-/)
        expect(data).to match_array(%w[data-member-search-user-id data-member-search-label])
      end
    end

    context 'when the owner, a member and a free user match' do
      render_views
      let(:options) { Capybara.string(response.body).all('[role="option"]').map(&:text) }

      before do
        sign_in owner
        owner.update!(name: 'cand-owner')
        create(:board_membership, board: board, user: create(:user, name: 'cand-member'))
        create(:user, name: 'cand-free')
        get :search, params: params.merge(member_query: 'cand-')
      end

      it 'offers the free user' do
        expect(options.join).to include('cand-free')
      end

      it 'omits the owner and the existing member' do
        expect(options.join).not_to match(/cand-owner|cand-member/)
      end
    end

    context 'when authenticated as admin' do
      render_views

      before { sign_in admin }

      it 'allows the search' do
        get :search, params: params.merge(member_query: 'a')
        expect(response).to have_http_status(:no_content)
      end

      it 'returns candidates', :aggregate_failures do
        create(:user, name: 'Yamada Taro')
        get :search, params: params.merge(member_query: 'yamada')
        expect(response).to have_http_status(:ok)
        expect(Capybara.string(response.body)).to have_css('[role="option"]', text: 'Yamada Taro')
      end
    end
  end

  describe 'parameter filtering' do
    it 'hides member_query from the logs' do
      filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
      expect(filter.filter(member_query: 'alice@example.com')).to eq(member_query: '[FILTERED]')
    end
  end

  describe 'POST #create' do
    context 'when authenticated as owner' do
      before { sign_in owner }

      it 'redirects after adding member by email' do
        post :create, params: { board_board_id: board.board_id, member_query: other_user.email }
        expect(response).to have_http_status(:redirect)
      end

      it 'adds member by email' do
        post :create, params: { board_board_id: board.board_id, member_query: other_user.email }
        expect(board.members.reload).to include(other_user)
      end

      it 'redirects after adding member by name' do
        post :create, params: { board_board_id: board.board_id, member_query: other_user.name }
        expect(response).to have_http_status(:redirect)
      end

      it 'adds member by name' do
        post :create, params: { board_board_id: board.board_id, member_query: other_user.name }
        expect(board.members.reload).to include(other_user)
      end

      it 'shows error flash when user not found' do
        post :create, params: { board_board_id: board.board_id, member_query: 'nonexistent@example.com' }
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'shows error when user is already a member' do
        create(:board_membership, board: board, user: other_user)
        post :create, params: { board_board_id: board.board_id, member_query: other_user.email }
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'adds the user given by user_id even when another user has the same name', :aggregate_failures do
        first = create(:user, name: 'same-name')
        second = create(:user, name: 'same-name')
        post :create, params: { board_board_id: board.board_id, user_id: second.id, member_query: 'same-name' }
        expect(board.members.reload).to include(second)
        expect(board.members).not_to include(first)
      end

      it 'prefers user_id over member_query' do
        post :create, params: { board_board_id: board.board_id, user_id: other_user.id, member_query: 'nobody' }
        expect(board.members.reload).to include(other_user)
      end

      it 'rejects an unknown user_id with 422' do
        post :create, params: { board_board_id: board.board_id, user_id: 0 }
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'does not fall back to member_query when user_id is unknown', :aggregate_failures do
        post :create, params: { board_board_id: board.board_id, user_id: 0, member_query: other_user.email }
        expect(response).to have_http_status(:unprocessable_content)
        expect(board.members.reload).not_to include(other_user)
      end

      it 'rejects a malformed user_id instead of casting it', :aggregate_failures do
        post :create, params: { board_board_id: board.board_id, user_id: "#{other_user.id}abc" }
        expect(response).to have_http_status(:unprocessable_content)
        expect(board.members.reload).not_to include(other_user)
      end

      it 'rejects a missing member_query and user_id even if a user has no name', :aggregate_failures do
        nameless = create(:user)
        nameless.update_column(:name, nil) # rubocop:disable Rails/SkipsModelValidations
        post :create, params: { board_board_id: board.board_id }
        expect(response).to have_http_status(:unprocessable_content)
        expect(board.members.reload).not_to include(nameless)
      end

      it 'refuses an ambiguous name and asks to pick a candidate', :aggregate_failures do
        create_list(:user, 2, name: 'same-name')
        post :create, params: { board_board_id: board.board_id, member_query: 'same-name' }
        expect(response).to have_http_status(:unprocessable_content)
        expect(flash[:alert]).to eq I18n.t('board_memberships.errors.ambiguous_name')
        expect(board.members.reload).to be_empty
      end

      it 'adds the only user with a given name' do
        user = create(:user, name: 'unique-name')
        post :create, params: { board_board_id: board.board_id, member_query: 'unique-name' }
        expect(board.members.reload).to include(user)
      end

      it 'rejects an existing member given by user_id with 422', :aggregate_failures do
        create(:board_membership, board: board, user: other_user)
        post :create, params: { board_board_id: board.board_id, user_id: other_user.id }
        expect(response).to have_http_status(:unprocessable_content)
        expect(board.board_memberships.where(user: other_user).count).to eq 1
      end

      it 'falls back to member_query when user_id is blank' do
        post :create, params: { board_board_id: board.board_id, user_id: '', member_query: other_user.email }
        expect(board.members.reload).to include(other_user)
      end
    end

    context 'when authenticated as non-owner' do
      before { sign_in other_user }

      it 'returns 403' do
        post :create, params: { board_board_id: board.board_id, member_query: 'someone@example.com' }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:membership) { create(:board_membership, board: board, user: other_user) }

    context 'when authenticated as owner' do
      before { sign_in owner }

      it 'redirects after removing member' do
        delete :destroy, params: { id: membership.id }
        expect(response).to have_http_status(:redirect)
      end

      it 'removes the membership' do
        delete :destroy, params: { id: membership.id }
        expect(BoardMembership.find_by(id: membership.id)).to be_nil
      end
    end

    context 'when authenticated as non-owner' do
      before { sign_in create(:user) }

      it 'returns 403' do
        delete :destroy, params: { id: membership.id }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when authenticated as admin' do
      before { sign_in admin }

      it 'removes member and redirects' do
        delete :destroy, params: { id: membership.id }
        expect(response).to have_http_status(:redirect)
      end
    end
  end
end
