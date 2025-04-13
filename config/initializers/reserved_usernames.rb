RESERVED_USERNAMES = YAML.load_file(Rails.root.join('config', 'reserved_usernames.yml'))["reserved_usernames"].map(&:downcase).freeze
