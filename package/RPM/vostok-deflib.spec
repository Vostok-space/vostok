Summary:        Default source-level library for Vostok - Oberon translator
Name:           vostok-deflib
Version:        0.0.2.dev
Release:        0%{?dist}
License:        LGPL
URL:            https://github.com/Vostok-space/vostok
Group:          User Development/Languages/Oberon
Source:         %{name}-%{version}.tar.bz2
BuildArch:      noarch

%description
Library provides runtime-code, basic input and output and some extra functions

%description -l ru
Предопределённая библиотека в исходном коде для Oberon-транслятора Восток.
Содержит код поддержки, основу ввода-вывода и немного дополнительных функций

%prep
%setup -q

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{_datadir}/vostok
cp -r library singularity %{buildroot}%{_datadir}/vostok/

%clean
rm -rf %{buildroot}

%files
%{_datadir}/vostok
