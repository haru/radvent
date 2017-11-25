FactoryGirl.define do
  factory :user do
    sequence :email do |n|
      "person#{n}@example.com"
    end

    sequence :name do |n|
      "person#{n}"
    end

    password "hogehoge"
  end

end
