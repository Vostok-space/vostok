Summary:        Oberon translator to C, Js, Java
Name:           vostok-bin
Version:        0.0.3.dev
Release:        0%{?dist}
License:        LGPL
URL:            https://github.com/Vostok-space/vostok
Group:          User Development/Languages/Oberon
Source:         %{name}-%{version}.tar.bz2

Requires:       vostok-deflib = 0.0.2.dev

%description
Oberon-07 translator from "Vostok"-project with defensive style of generated code

%description -l ru
Транслятор Oberon-07 проекта Восток с генерацией защищённого кода

%prep
%setup -q

%build
mkdir result
./init.sh && result/bs-ost run make.Build -infr . -m source
result/ost to-bin Translator.Go result/ost -infr . -m source -cc "cc -O1 -flto -s"

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{_bindir}
install result/ost %{buildroot}%{_bindir}/ost

%check
%{buildroot}%{_bindir}/ost run 'Out.String("Работает!"); Out.Ln' -infr .

%clean
rm -rf %{buildroot}

%files
%{_bindir}/ost
