FactoryBot.define do
  factory :comment do
    user_name {'nanonanomachine'}
    body {'body'}
    association :item
  end
end
