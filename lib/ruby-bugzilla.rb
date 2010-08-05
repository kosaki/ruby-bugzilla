# bugzilla.rb
# Copyright (C) 2010 Red Hat, Inc.
#
# Authors:
#   Akira TAGOH  <tagoh@redhat.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330,
# Boston, MA 02111-1307, USA.

require 'xmlrpc/client'


=begin rdoc

== Bugzilla

=end

module Bugzilla

  VERSION = "0.1"

=begin rdoc

=== Bugzilla::XMLRPC

=end

  class XMLRPC

=begin rdoc

==== Bugzilla::XMLRPC#new(server, port = 443)

=end

    def initialize(server, port = 443)
      use_ssl = port == 443 ? true : false
      @xmlrpc = ::XMLRPC::Client.new(server, '/xmlrpc.cgi', port, nil, nil, nil, nil, use_ssl, 60)
    end # def initialize

=begin rdoc

==== Bugzilla::XMLRPC#call(cmd, params, user = nil, password = nil)

=end

    def call(cmd, params = {}, user = nil, password = nil)
      params = {} if params.nil?
      params['Bugzilla_login'] = user unless user.nil? || password.nil?
      params['Bugzilla_password'] = password unless user.nil? || password.nil?
      @xmlrpc.call(cmd, params)
    end # def call

  end # class XMLRPC

=begin rdoc

=== Bugzilla::Skeleton

=end

  class Skeleton

    def initialize(iface)
      @iface = iface
    end # def initialize

    def method_missing(symbol, *args)
      m = "_#{symbol}"
      klass = self.class.to_s.sub(/\ABugzilla::/, '')
      fm = "#{klass}.#{symbol}"
      if self.respond_to?(m) then
        __send__(m, fm, *args)
      else
        raise NoMethodError, sprintf("No such Bugzilla APIs: %s.%s", klass, symbol)
      end
    end # def method_missing

  end # class Skeleton

=begin rdoc

=== Bugzilla::Bugzilla

Bugzilla::Bugzilla class is to access the
Bugzilla::WebService::Bugzilla API that provides functions
tell you about Bugzilla in general.

=end

  class Bugzilla < Skeleton

=begin rdoc

==== Bugzilla::Bugzilla#check_version(version_)

Returns Array contains the result of the version check and
Bugzilla version that is running on.

=end

    def check_version(version_)
      v = version
      f = false
      if v.kind_of?(Hash) && v.include?("version") &&
          v['version'] >= "#{version_}" then
	f = true
      end

      [f, v['version']]
    end # def check_version

=begin rdoc

==== Bugzilla::Bugzilla#requires_version(cmd, version_)

Raise an exception if the Bugzilla doesn't satisfy
the requirement of the _version_.

=end

    def requires_version(cmd, version_)
      v = check_version(version_)
      raise NoMethodError, sprintf("%s is not supported in Bugzilla %s", cmd, v[1]) unless v[0]
    end # def requires_version

=begin rdoc

==== Bugzilla::Bugzilla#version

Raw Bugzilla API to obtain the Bugzilla version.

See http://www.bugzilla.org/docs/tip/en/html/api/Bugzilla/WebService/Bugzilla.html

=end

=begin rdoc

==== Bugzilla::Bugzilla#extensions

Raw Bugzilla API to obtain the information about
the extensions that are currently installed and enabled in
the Bugzilla.

See http://www.bugzilla.org/docs/tip/en/html/api/Bugzilla/WebService/Bugzilla.html

=end

=begin rdoc

==== Bugzilla::Bugzilla#timezone

Raw Bugzilla API to obtain the timezone that Bugzilla
expects dates and times in.

See http://www.bugzilla.org/docs/tip/en/html/api/Bugzilla/WebService/Bugzilla.html

=end

=begin rdoc

==== Bugzilla::Bugzilla#time

Raw Bugzilla API to obtain the information about what time
the bugzilla server thinks it is, and what timezone it's
running on.

See http://www.bugzilla.org/docs/tip/en/html/api/Bugzilla/WebService/Bugzilla.html

=end

    protected

    def _version(cmd, *args)
      @iface.call(cmd)
    end # def _version

    def _extensions(cmd, *args)
      requires_version(cmd, 3.2)

      @iface.call(cmd)
    end # def _extensions

    def _timezone(cmd, *args)
      @iface.call(cmd)
    end # def _timezone

    def _time(cmd, *args)
      requires_version(cmd, 3.4)

      @iface.call(cmd)
    end # def _time

  end # class Bugzilla

=begin rdoc

=== Bugzilla::APITemplate

=end

  class APITemplate < Skeleton

    def initialize(iface)
      super

      @bz = Bugzilla.new(iface)
    end # def initialize

    def method_missing(symbol, *args)
      if @bz.respond_to?(symbol) then
        @bz.__send__(symbol, *args)
      else
        super
      end
    end # def method_missing

  end # class APITemplate

=begin rdoc

=== Bugzilla::Product

Bugzilla::Product class is to access
the Bugzilla::WebService::Product API that allows you to
list the available Products and get information about them.

=end

  class Product < APITemplate

=begin rdoc

==== Bugzilla::Product#selectable_products

Returns the products that the user can search on as Hash
contains the product name as the Hash key and Array as the
value. Array contains the list of _id_, _name_,
_description_ and _internals_ according to API documentation
though, actually the component, the version and the target
milestone.

=end

    def selectable_products
      ids = get_selectable_products
      get(ids)
    end # def selectable_products

=begin rdoc

==== Bugzilla::Product#enterable_products

Returns the products that the user can enter bugs against
as Hash contains the product name as the Hash key and Array
as the value. Array contains the list of _id_, _name_,
_description_ and _internals_ according to API documentation
though, actually the component, the version and the target
milestone.

=end

    def enterable_products
      ids = get_enterable_products
      get(ids)
    end # def enterable_products

=begin rdoc

==== Bugzilla::Product#accessible_products

Returns the products that the user can search or enter bugs
against as Hash contains the product name as the Hash key
and Array as the value. Array contains the list of _id_,
_name_, _description_ and _internals_ according to API
documentation though, actually the component, the version
and the target milestone.

=end

    def accessible_products
      ids = get_accessible_products
      get(ids)
    end # def accessible_products

=begin rdoc

==== Bugzilla::Product#get_selectable_products

Raw Bugzilla API to obtain the products that the user can
search on.

See http://www.bugzilla.org/docs/tip/en/html/api/Bugzilla/WebService/Product.html

=end

=begin rdoc

==== Bugzilla::Product#get_enterable_products

Raw Bugzilla API to obtain the products that the user can
enter bugs against.

See http://www.bugzilla.org/docs/tip/en/html/api/Bugzilla/WebService/Product.html

=end

=begin rdoc

==== Bugzilla::Product#get_accessible_products

Raw Bugzilla API to obtain the products that the user can
search or enter bugs against.

See http://www.bugzilla.org/docs/tip/en/html/api/Bugzilla/WebService/Product.html

=end

    protected

    def _get_selectable_products(cmd, *args)
      @iface.call(cmd)
    end # def _get_selectable_products

    def _get_enterable_products(cmd, *args)
      @iface.call(cmd)
    end # def _get_entrable_products

    def _get_accessible_products(cmd, *args)
      @iface.call(cmd)
    end # def _get_accessible_products

    def _get(cmd, ids, *args)
      if ids.kind_of?(Hash) && !ids.include?(:ids) then
        raise ArgumentError, "Invalid parameter"
      elsif ids.kind_of?(Array) then
	ids = {'ids'=>ids}
      else
        ids = {'ids'=>[ids]}
      end

      @iface.call(cmd, ids)
    end # def _get

  end # class Product

=begin rdoc

=== Bugzilla::Bug

Bugzilla::Bug class is to access
the Bugzilla::WebService::Bug API that allows you to file
a new bug in Bugzilla or get information about bugs that
have already been filed.

=end

  class Bug < APITemplate

=begin rdoc

==== Bugzilla::Bug#fields(params)

Raw Bugzilla API to obtain the information about valid bug
fields, including the lists of legal values for each field.

See http://www.bugzilla.org/docs/tip/en/html/api/Bugzilla/WebService/Bug.html

=end

=begin rdoc

==== Bugzilla::Bug#legal_values(params)

Raw Bugzilla API to obtain the information what values are
allowed for a particular field.

See http://www.bugzilla.org/docs/tip/en/html/api/Bugzilla/WebService/Bug.html

=end

=begin rdoc

==== Bugzilla::Bug#attachments(params)

Raw Bugzilla API to obtain the information about
attachments, given a list of bugs and/or attachment ids.

See http://www.bugzilla.org/docs/tip/en/html/api/Bugzilla/WebService/Bug.html

=end

=begin rdoc

==== Bugzilla::Bug#comments(params)

Raw Bugzilla API to obtain the information about comments,
given a list of bugs and/or comment ids.

See http://www.bugzilla.org/docs/tip/en/html/api/Bugzilla/WebService/Bug.html

=end

=begin rdoc

==== Bugzilla::Bug#get(params)

Raw Bugzilla API to obtain the information about particular
bugs in the database.

=end

=begin rdoc

==== Bugzilla::Bug#history(params)

Raw Bugzilla API to obtain the history of changes for
particular bugs in the database.

=end

=begin rdoc

==== Bugzilla::Bug#search(params)

Raw Bugzilla API to search for bugs based on particular
criteria.

=end

    protected

    def _fields(cmd, *args)
      requires_version(cmd, 3.6)
      params = {}

      if args[0].kind_of?(Array) then
        x = args[0].map {|x| x.kind_of?(Integer)}.uniq
        if x.length == 1 && x[0] then
          params['ids'] = args[0]
        else
          x = args[0].map {|x| x.kind_of?(String)}.uniq
          if x.length == 1 && x[0] then
            params['names'] = args[0]
          end
        end
      elsif args[0].kind_of?(Hash) then
	params = args[0]
      elsif args[0].kind_of?(Integer) then
	params['ids'] = [args[0]]
      elsif args[0].kind_of?(String) then
	params['names'] = [args[0]]
      elsif args[0].nil? then
      else
        raise ArgumentError, "Invalid parameters"
      end

      @iface.call(cmd, params)
    end # def _fields

    def _legal_values(cmd, *args)
      raise ArgumentError, "Invalid parameters" unless args[0].kind_of?(Hash)

      @iface.call(cmd, args[0])
    end # def _legal_values

    def _attachments(cmd, *args)
      requires_version(cmd, 3.6)

      raise ArgumentError, "Invalid parameters" unless args[0].kind_of?(Hash)

      @iface.call(cmd, args[0])
    end # def _attachments

    def _comments(cmd, *args)
      requires_version(cmd, 3.4)

      raise ArgumentError, "Invalid parameters" unless args[0].kind_of?(Hash)

      @iface.call(cmd, args[0])
    end # def _comments

    def _get(cmd, *args)
      params = {}

      if args[0].kind_of?(Hash) then
        params = args[0]
      elsif args[0].kind_of?(Array) then
	params['ids'] = args[0]
      elsif args[0].kind_of?(Integer) ||
          args[0].kind_of?(String) then
	params['ids'] = [args[0]]
      else
        raise ArgumentError, "Invalid parameters"
      end
      if check_version(3.4)[0] then
        params['permissive'] = true
      end

      @iface.call(cmd, params)
    end # def _get

    def _history(cmd, *args)
      requires_version(cmd, 3.4)

      params = {}

      if args[0].kind_of?(Hash) then
        params = args[0]
      elsif args[0].kind_of?(Array) then
	params['ids'] = args[0]
      elsif args[0].kind_of?(Integer) ||
          args[0].kind_of?(String) then
	params['ids'] = [args[0]]
      else
        raise ArgumentError, "Invalid parameters"
      end

      @iface.call(cmd, params)
    end # def _history

    def _search(cmd, *args)
      requires_version(cmd, 3.4)

      raise ArgumentError, "Invalid parameters" unless args[0].kind_of?(Hash)

      @iface.call(cmd, args[0])
    end # def _search

    def __create(cmd, *args)
      # FIXME
    end # def _create

    def __add_attachment(cmd, *args)
      requires_version(cmd, 4.0)
      # FIXME
    end # def _add_attachment

    def __add_comment(cmd, *args)
      requires_version(cmd, 3.2)
      # FIXME
    end # def _add_comment

    def __update(cmd, *args)
      requires_version(cmd, 4.0)
      # FIXME
    end # def _update

    def __update_see_also(cmd, *args)
      requires_version(cmd, 3.4)
      # FIXME
    end # def _update_see_also

  end # class Bug

=begin rdoc

=== Bugzilla::User

Bugzilla::User class is to access the
Bugzilla::WebService::User API that allows you to create
User Accounts and log in/out using an existing account.

=end

  class User < APITemplate

    protected

    def __login(cmd, *args)
      # FIXME
    end # def _login

    def __logout(cmd, *args)
      # FIXME
    end # def _logout

    def __offer_account_by_email(cmd, *args)
      # FIXME
    end # def _offer_account_by_email

    def __create(cmd, *args)
      # FIXME
    end # def _create

    def __get(cmd, *args)
      requires_version(cmd, 3.4)
      # FIXME
    end # def _get

  end # class User

end # module Bugzilla

if $0 == __FILE__ then
  require 'pp'

  xmlrpc = Bugzilla::XMLRPC.new('bugzilla.redhat.com')
  p = Bugzilla::Bug.new(xmlrpc)
  p p.history(618271)
  exit
  pp p.get(618271)
  p p.comments({'ids'=>[618271]})
  p p.attachments({'ids'=>[618271]})
  p p.legal_values({'field'=>'product'})
  p p.fields
  exit
  p = Bugzilla::Bugzilla.new(xmlrpc)
  p p.version
  p p.extensions
  p p.time
  exit
  p = Bugzilla::Product.new(xmlrpc)
  ids = p.get_selectable_products
  p p.get(ids)
  p p.get_enterable_products
  p p.get_accessible_products
end
