# Written by http://www.reddit.com/u/ZedFish for the r/AFL Discord Server

::RBNACL_LIBSODIUM_GEM_LIB_PATH = 'C:\libsodium\libsodium.dll'

require 'discordrb'
require 'active_support/core_ext/enumerable'
require 'yaml'

CONFIG = YAML.loadfile("data/config.yml")
TEAMS = YAML.loadfile("data/teams.yml")
GROUPS = YAML.loadfile("data/groups.yml")
DESCS = YAML.loadfiles("data/descriptions.yml")

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

TEAMS.each do |team, array|
	teamnames << array
end

teamnames.flatten!

teamroles = teamnames.join(" | ")
optroles = GROUPS.join(" | ")

# COMMANDS TIME

bot.command(:team,
            attributes = 
                {description: DESCS['team_desc'],
                 usage: DESCS['team_usage']}) do |event, *team|
    
    newteam = team.join(" ").downcase

    unless TEAMS.values.flatten.include?(newteam)
        bot.send_temporary_message(event.channel.id, content = "#{event.author.mention}: \<:bt:246541254182174720> THAT WAS OUT OF BOUNDS! `#{newteam}` is not an accepted input!", timeout = 10)
        sleep 10
        event.message.delete
        raise ArgumentError.new("THAT WAS OUT OF BOUNDS!")
    end

    if event.author.id == 307633569382268928
        bot.send_temporary_message(bot.channel.id, content = "I thought you were settled, Jazi! PM @ZedFish#2430 to plead your case to the DraftBot Tribunal.")
        puts("///// Jazi asked again, please see to him /////")
        sleep 10
        event.message.delete
    else
    
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
        TEAMS.each_with_index do |(key,array), i|
            if array.include?(newteam)
                to_add = event.server.roles.find {|r| r.name == key}
                event.author.modify_roles(to_add, drop_array)
                puts("Removed #{drop_array_names} from #{event.author.username}##{event.author.discriminator} (#{event.author.nick})")
                puts("Added role #{to_add.name} to #{event.author.username}##{event.author.discriminator} (#{event.author.nick})")
            
                bot.send_temporary_message(event.channel.id, content = "#{event.author.mention} is now a fan of #{to_add.name}!", timeout = 10)
                sleep 10
                event.message.delete
                break
            end
        end
    end
end

bot.command(:noteam,
            attributes =
                {description: DESCS['noteam_desc'],
                 usage: DESCS['noteam_usage']}) do |event|

    # This is essentially the same as Step 1 of :team. Removes any teams in case the user is ~done~ with the concept of teams.
    drop_array = []
    to_add = event.server.roles.find {|r| r.name == "Confirmed reddit user"}
    event.author.roles.each do |oldteam|
        if TEAMS.include?(oldteam.name)
            drop_array << oldteam
        end
    end
    event.author.modify_roles(to_add, drop_array)
    puts("Removed all teams from #{event.author.username}##{event.author.discriminator} (#{event.author.nick})")

    bot.send_temporary_message(event.channel.id, content = "#{event.author.mention} has no team!", timeout = 10)
    sleep 10
    event.message.delete

end


# Optin Roles are special. Ask ZedFish#2430 (/u/ZedFish) for more details.
# These next two commands are essentially easier versions of the :team commands.

bot.command(:optin,
        attributes =
            {description: DESCS['optin_desc'],
             usage: DESCS['optin_usage']}) do |event, *optin|
  
    newoptin = titlecase(optin.join(" "))

    unless GROUPS.flatten.include?(newoptin)
        bot.send_temporary_message(event.channel.id, content = "#{event.author.mention}: \<:bt:246541254182174720> THAT WAS OUT OF BOUNDS! `#{newoptin}` is not an accepted input!", timeout = 10)
        sleep 10
        event.message.delete
        raise ArgumentError.new("THAT WAS OUT OF BOUNDS!")
    end

    if GROUPS.include?(newoptin)
        to_add = event.server.roles.find {|r| r.name == newoptin}
        event.author.add_role(to_add)
        puts("Added role #{newoptin} to #{event.author.username}##{event.author.discriminator} (#{event.author.nick})")
    end
    bot.send_temporary_message(event.channel.id, content = "#{event.author.mention} is now a part of the #{newoptin} group!", timeout = 10)
    sleep 10
    event.message.delete

end
 
bot.command(:optout,
        attributes =
            {description: DESCS['optout_desc'],
             usage: DESCS['optout_usage']}) do |event, *optout|

    newoptout = titlecase(optout.join(" "))

    unless GROUPS.flatten.include?(newoptout)
        bot.send_temporary_message(event.channel.id, content = "#{event.author.mention}: \<:bt:246541254182174720> THAT WAS OUT OF BOUNDS! `#{newoptout}` is not an accepted input!", timeout = 10)
        sleep 10
        event.message.delete
        raise ArgumentError.new("THAT WAS OUT OF BOUNDS!")
    end

    if GROUPS.include?(newoptout)
        to_remove = event.server.roles.find {|r| r.name == newoptout}
        event.author.remove_role(to_remove)
        puts("Removed role #{newoptout} from #{event.author.username}##{event.author.discriminator} (#{event.author.nick})")
    end
    bot.send_temporary_message(event.channel.id, content = "#{event.author.mention} is no longer a part of the #{newoptout} group!", timeout = 10)
    sleep 10
    event.message.delete

end


# Let's boot this baby UP!
bot.ready do |event|

    puts("--------------------------------------------------------")
    puts("Logged in and successfully connected as #{bot.name}.")
    puts("--------------------------------------------------------")
    bot.game = CONFIG['game']

end

bot.run