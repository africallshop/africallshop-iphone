# -*- rpm-spec -*-

## rpmbuild options

Name:           belle-sip
Version:        1.2.1
Release:        %(version=`git describe --tags --abbrev=40 | sed -rn 's/^.*-([0-9]+)-g[a-z0-9]{40}$/\1/p'` && if test -z "$version" ; then echo 0 ; else echo $version ; fi)%{?dist}
Summary:        Linphone sip stack

Group:          Applications/Communications
License:        GPL
URL:            http://www.belle-sip.org
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Source0: 	%{name}-%{version}.tar.gz
%description
Belle-sip is an object oriented c written SIP stack used by Linphone.

%package devel
Summary:       Development libraries for belle-sip
Group:         Development/Libraries
Requires:      %{name} = %{version}-%{release}

%description    devel
Libraries and headers required to develop software with belle-sip

%prep
%setup -q

%build
%configure \
	--disable-tests --docdir=%{_docdir} 
%__make %{?_smp_mflags}


%install
rm -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT

%clean
rm -rf $RPM_BUILD_ROOT

%post -p /sbin/ldconfig

%postun -p /sbin/ldconfig


%files 
%defattr(-,root,root)
%doc AUTHORS ChangeLog COPYING NEWS README
%{_libdir}/*.so.*

%files devel
%defattr(-,root,root)
%{_includedir}/belle-sip
%{_libdir}/libbellesip.a
%{_libdir}/libbellesip.la
%{_libdir}/libbellesip.so
%{_libdir}/pkgconfig/belle-sip.pc

%changelog
* Mon Aug 19 2013 jehan.monnier <jehan.monnier@linphone.org>
- Initial RPM release.
