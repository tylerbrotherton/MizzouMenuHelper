project('mizzou-dining', 'vala', 'c',
  version: '1.0.0',
  meson_version: '>= 0.56.0'
)

gnome = import('gnome')

# Dependencies
dependencies = [
  dependency('gtk+-3.0'),
  dependency('libsoup-2.4'),
  dependency('json-glib-1.0'),
  dependency('gee-0.8'),
]

# Application sources
sources = [
  'mizzou-dining.vala',
]

# Compile resources
resources = gnome.compile_resources(
  'mizzou-dining-resources',
  'mizzou-dining.gresource.xml',
  source_dir: '.',
)

# Build executable
executable(
  'mizzou-dining',
  sources,
  resources,
  dependencies: dependencies,
  install: true,
)

# Desktop file
desktop_file = 'edu.missouri.dining.desktop'
desktop_conf = configuration_data()
desktop_conf.set('bindir', join_paths(get_option('prefix'), get_option('bindir')))

configure_file(
  input: desktop_file + '.in',
  output: desktop_file,
  configuration: desktop_conf,
  install: true,
  install_dir: join_paths(get_option('datadir'), 'applications')
)

# AppData file
install_data(
  'edu.missouri.dining.appdata.xml',
  install_dir: join_paths(get_option('datadir'), 'metainfo')
)

# Icon
install_data(
  'mizzou-dining.svg',
  install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', 'scalable', 'apps'),
  rename: 'edu.missouri.dining.svg'
)
