  echo "updating from git.."
  git pull
  
  echo "updating gems.."
  bundle update
  
  echo "installing gems.."
  bundle install

  echo "starting bot.."
  bundle exec ruby main.rb