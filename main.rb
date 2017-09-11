# AUTHOR: Miller Richey (github.com/ZedFish) (reddit.com/u/ZedFish)

::RBNACL_LIBSODIUM_GEM_LIB_PATH = 'C:\libsodium\libsodium.dll'

require 'discordrb'
require 'active_support/core_ext/enumerable'
require 'yaml'

CONFIG = YAML.load_file("data/config.yml")
TEAMS = YAML.load_file("data/teams.yml")
GROUPS = YAML.load_file("data/groups.yml")
DESCS = YAML.load_file("data/descriptions.yml")

bot = Discordrb::Commands::CommandBot.new(name: CONFIG['name'], 
                                          token: CONFIG['token'], 
                                          client_id: CONFIG['client_id'], 
                                          prefix: CONFIG['prefix'],
                                          help_command: CONFIG['help_command'])

# This function translates user inputs "port adelaide", "PoRt AdElAiDe", etc., into "Port Adelaide", for example
def titlecase(str)
    "#{str.split.each{|str| str.capitalize!}.join(" ")}"
end

teamnames = []
groupnames = []

TEAMS.each do |team, array|
	teamnames << array
end

GROUPS.each do |group, array|
    groupnames << array
end

teamnames.flatten!
groupnames.flatten!

teamroles = teamnames.join(" | ")
optroles = groupnames.join(" | ")

# COMMANDS TIME

bot.command(:team, attributes = {description: DESCS['team_desc'],
                                 usage: DESCS['team_usage']}) do |event, *team|
    
    newteam = team.join(" ").downcase

    unless TEAMS.values.flatten.include?(newteam)
        bot.send_temporary_message(event.channel.id, content = "#{event.author.mention}: \<:bt:246541254182174720> THAT WAS OUT OF BOUNDS! `#{newteam}` is not an accepted input!", timeout = 10)
        sleep 10
        event.message.delete
        raise ArgumentError.new("THAT WAS OUT OF BOUNDS!")
    end
    
    # First, we want to get rid of any old teams the user has. Who even has two teams? Unaustralian! We'll catalogue what we want
    # to drop, and their names for admin purposes.
    drop_array = []
    drop_array_names = []
    event.author.roles.each do |oldteam|
        if TEAMS.has_key?(oldteam.name)
            drop_array << oldteam
        end
    end
    drop_array.each do |teamrole|
        drop_array_names << teamrole.name
    end

    # Now we queue up the role we want to add
    TEAMS.each do |key,array|
        if array.include?(newteam)
            to_add = event.server.roles.find {|r| r.name == key}
            event.author.modify_roles(to_add, drop_array)
            date_time = Time.now.strftime("%Y/%m/%d %H:%M").to_s
            puts("#{date_time}: Removed #{drop_array_names} from #{event.author.username}##{event.author.discriminator} (#{event.author.nick})")
            File.open("userlog.txt", 'a') { |file| file.write("#{date_time}: Removed #{drop_array_names} from #{event.author.username}##{event.author.discriminator} (#{event.author.nick})") }
            puts("#{date_time}: Added role #{to_add.name} to #{event.author.username}##{event.author.discriminator} (#{event.author.nick})")
            File.open("userlog.txt", 'a') { |file| file.write("#{date_time}: Added role #{to_add.name} to #{event.author.username}##{event.author.discriminator} (#{event.author.nick})") }
        
            bot.send_temporary_message(event.channel.id, content = "#{event.author.mention} is now a fan of #{to_add.name}!", timeout = 10)
            sleep 10
            event.message.delete
            break
        end
    end
end

bot.command(:noteam, attributes = {description: DESCS['noteam_desc'],
                          usage: DESCS['noteam_usage']}) do |event|

    # This is essentially the same as Step 1 of :team. Removes any teams in case the user is ~done~ with the concept of teams.
    drop_array = []
    to_add = event.server.roles.find {|r| r.name == "Confirmed"}
    event.author.roles.each do |oldteam|
        if TEAMS.include?(oldteam.name)
            drop_array << oldteam
        end
    end
    event.author.modify_roles(to_add, drop_array)
    date_time = Time.now.strftime("%Y/%m/%d %H:%M").to_s
    puts("#{date_time}: Removed all teams from #{event.author.username}##{event.author.discriminator} (#{event.author.nick})")
    File.open("userlog.txt", 'a') { |file| file.write("#{date_time}: Removed all teams from #{event.author.username}##{event.author.discriminator} (#{event.author.nick})") }

    bot.send_temporary_message(event.channel.id, content = "#{event.author.mention} has no team!", timeout = 10)
    sleep 10
    event.message.delete

end


# Optin Roles are special. Ask ZedFish#2430 (/u/ZedFish) for more details.
# These next two commands are essentially easier versions of the :team commands.

bot.command(:optin, attributes = {description: DESCS['optin_desc'],
                                  usage: DESCS['optin_usage']}) do |event, *optin|
  
    newoptin = optin.join(" ")

    unless GROUPS.values.flatten.include?(newoptin)
        bot.send_temporary_message(event.channel.id, content = "#{event.author.mention}: \<:bt:246541254182174720> THAT WAS OUT OF BOUNDS! `#{newoptin}` is not an accepted input!", timeout = 10)
        sleep 10
        event.message.delete
        raise ArgumentError.new("THAT WAS OUT OF BOUNDS!")
    end

    GROUPS.each do |key, array|
        if array.include?(newoptin)
            to_add = event.server.roles.find {|r| r.name == newoptin}
            event.author.add_role(to_add)
            date_time = Time.now.strftime("%Y/%m/%d %H:%M").to_s
            puts("#{date_time}: Added role #{newoptin} to #{event.author.username}##{event.author.discriminator} (#{event.author.nick})")
            File.open("userlog.txt", 'a') { |file| file.write("#{date_time}: Added role #{newoptin} to #{event.author.username}##{event.author.discriminator} (#{event.author.nick})") }
            
            bot.send_temporary_message(event.channel.id, content = "#{event.author.mention} is now a part of the #{newoptin} group!", timeout = 10)
            sleep 10
            event.message.delete
            break
        end
    end

    if newoptin == "All"
        add_array = []
        event.server.roles.each do |role|
            if GROUPS.include?(role.name)
                add_array << role
            end
        end
        event.author.add_role(add_array)
        date_time = Time.now.strftime("%Y/%m/%d %H:%M").to_s
        puts("#{date_time}: Added all Opt-in roles to #{event.author.username}##{event.author.discriminator} (#{event.author.nick})")
        File.open("userlog.txt", 'a') { |file| file.write("#{date_time}: Added all Opt-in roles to #{event.author.username}##{event.author.discriminator} (#{event.author.nick})") }
        bot.send_temporary_message(event.channel.id, content = "#{event.author.mention} is now a part of all optin groups!", timeout = 10)
        sleep 10
        event.message.delete
    end
end
 
bot.command(:optout,attributes = {description: DESCS['optout_desc'],
                                  usage: DESCS['optout_usage']}) do |event, *optout|

    newoptout = optout.join(" ")

    unless GROUPS.values.flatten.include?(newoptout)
        bot.send_temporary_message(event.channel.id, content = "#{event.author.mention}: \<:bt:246541254182174720> THAT WAS OUT OF BOUNDS! `#{newoptout}` is not an accepted input!", timeout = 10)
        sleep 10
        event.message.delete
        raise ArgumentError.new("THAT WAS OUT OF BOUNDS!")
    end

    GROUPS.each do |key, array|
        if array.include?(newoptout)
            to_remove = event.server.roles.find {|r| r.name == key}
            event.author.remove_role(to_remove)
            date_time = Time.now.strftime("%Y/%m/%d %H:%M").to_s
            puts("#{date_time}: Removed role #{newoptout} from #{event.author.username}##{event.author.discriminator} (#{event.author.nick})")
            File.open("userlog.txt", 'a') { |file| file.write("#{date_time}: Removed role #{newoptout} from #{event.author.username}##{event.author.discriminator} (#{event.author.nick})") }
            
            bot.send_temporary_message(event.channel.id, content = "#{event.author.mention} is no longer a part of the #{newoptout} group!", timeout = 10)
            sleep 10
            event.message.delete
            break
        end
    end
end


# Let's boot this baby UP!
bot.ready do |event|

    puts("--------------------------------------------------------")
    puts("Logged in and successfully connected as #{bot.name}.")
    puts("--------------------------------------------------------")
    bot.game = CONFIG['game']

end

bot.run
