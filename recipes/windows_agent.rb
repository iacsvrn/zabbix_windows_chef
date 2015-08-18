# Author:: H. "Waldo" Grunenwald
# Cookbook Name:: zabbix_windows
# Recipe:: windows_agent
#
# Copyright 2012, Ernst Publishing
# License: Apache 2.0

# Install the Zabbix Windows Agent
# see the perl default recipe for pieces

installdir	= node.zabbix_windows.agent.install_dir
includedir	= node.zabbix_windows.agent.include_dir

installer	= "zabbix_agentd#{node['zabbix_windows']['agent']['windows_bitness']}.exe"
getter		= "zabbix_get#{node['zabbix_windows']['agent']['windows_bitness']}.exe"
sender		= "zabbix_sender#{node['zabbix_windows']['agent']['windows_bitness']}.exe"


#directory node['zabbix_windows']['agent']['include_dir'] do
#	action :create
#	recursive true
#	inherits true
#end

directory node['zabbix_windows']['log_dir'] do
	action :create
	recursive true
	inherits true
end


cookbook_file "#{installdir}\\#{installer}" do
	source "#{installer}"
	action :create_if_missing
	inherits true
end

cookbook_file "#{installdir}\\#{getter}" do
	source "#{getter}"
	action :create_if_missing
	inherits true
end

cookbook_file "#{installdir}\\#{sender}" do
	source "#{sender}"
	action :create_if_missing
	inherits true
end

template "#{installdir}\\agent_include" do
	source "agent_include.erb"
	action :create_if_missing
	inherits true
	notifies :restart, "service[Zabbix Agent]"
end

template "#{installdir}\\zabbix_agentd.conf" do
	source "zabbix_agentd.conf.erb"
	action :create_if_missing
	inherits true
	notifies :restart, "service[Zabbix Agent]"
end


# Check Windows Service
require 'win32ole'
zabbixservice = 'Zabbix Agent'
wmi = WIN32OLE.connect("winmgmts://")
services = wmi.ExecQuery("Select * from Win32_Service where Name = '#{zabbixservice}'")
if services.count >= 1
	#service exists
else
	#INSTALL AWAY!

	# Back to Chef-land
	execute "Install Zabbix" do
		command "#{installdir}\\#{installer} --config #{installdir}\\zabbix_agentd.conf --install"
		#not_if { File.exists?("#{node['perl']['install_dir']}\\perl\\bin\\perl.exe") }
	end
end

# Define zabbix_agentd service
#service "zabbix_agentd" do
service "Zabbix Agent" do
  supports :status => true, :start => true, :stop => true, :restart => true
  action [ :enable ]
  action [ :start ]
end
