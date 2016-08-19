class Comentario < ActiveRecord::Base
  self.table_name = :comentarios
  self.primary_key = 'id'

  belongs_to :especie
  belongs_to :usuario
  belongs_to :categoria_comentario, :class_name => 'CategoriaComentario', :foreign_key => 'categoria_comentario_id', :dependent => :destroy

  has_ancestry

  # Atributo para tener la cuenta de los comentarios del historial
  attr_reader :cuantos
  attr_writer :cuantos

  # Para evitar el google captcha a los usuarios administradores
  attr_reader :con_verificacion
  attr_writer :con_verificacion

  # Para saber si es un comentario de un administrador
  attr_reader :es_admin
  attr_writer :es_admin

  # Para saber si es una respuesta del usuario
  attr_reader :es_respuesta
  attr_writer :es_respuesta

  validates_presence_of :comentario
  validates_presence_of :especie_id
  validates_presence_of :categoria_comentario_id
  validates_presence_of :nombre, :if => 'usuario_id.blank?'

  email_name_regex  = '[\w\.%\+\-]+'.freeze
  domain_head_regex = '(?:[A-Z0-9\-]+\.)+'.freeze
  domain_tld_regex  = '(?:[A-Z]{2}|com|org|net|edu|gov|mil|biz|info|mobi|name|aero|jobs|museum)'.freeze
  email_regex       = /\A#{email_name_regex}@#{domain_head_regex}#{domain_tld_regex}\z/i
  bad_email_message = "no tiene la estructura apropiada.".freeze

  validates_format_of :correo, :with => email_regex, :message => bad_email_message, :if => 'usuario_id.blank?'
  validates_length_of :correo, :within => 6..100, :if => 'usuario_id.blank?'

  after_create :idABase32

  scope :join_especies,-> { joins('LEFT JOIN especies ON especies.id=comentarios.especie_id') }
  scope :join_adicionales,-> { joins('LEFT JOIN adicionales ON adicionales.especie_id=comentarios.especie_id') }
  scope :join_usuarios,-> { joins('LEFT JOIN usuarios u ON u.id=comentarios.usuario_id') }
  scope :join_usuarios2,-> { joins('LEFT JOIN usuarios u2 ON u2.id=comentarios.usuario_id2') }
  scope :select_basico,-> { select("comentarios.id, comentario, correo, comentarios.nombre as c_nombre, usuario_id, usuario_id2,
comentarios.especie_id, comentarios.ancestry, comentarios.created_at, comentarios.updated_at,
comentarios.estatus, fecha_estatus, categoria_comentario_id, comentarios.institucion AS c_institucion,
CONCAT(u.grado_academico,' ', u.nombre, ' ', u.apellido) AS u_nombre, u.email AS u_email,
u.institucion as u_institucion, nombre_cientifico, nombre_comun_principal, foto_principal,
CONCAT(u2.grado_academico,' ', u2.nombre, ' ', u2.apellido) AS u2_nombre") }
  scope :datos_basicos,-> { select_basico.join_usuarios.join_usuarios2.join_especies.join_adicionales }

  POR_PAGINA_PREDETERMINADO = 10
  RESUELTOS = [3,4]

  def self.options_for_select
    [['No público y pendiente',1],['Público y pendiente',2],['Público y resuelto',3],['No público y resuelto',4],['Eliminar',5]]
  end

  def idABase32
    Comentario.transaction do
      idBase32 = Comentario.where(:id => '', :created_at => self.created_at.to_time, :comentario => self.comentario)[0].idConsecutivo.to_s(32)
      update_column(:id, idBase32)
    end
  end

  def completa_nombre_correo
    if usuario_id.present?
      begin  # Por si viene del scope datos_basicos y encontro el usuario
        self.nombre = u_nombre
        self.correo = u_email
        self.institucion = u_institucion
      rescue
        begin  # Por si no tenia usuario_id, solo les pego los campos que tambien viene del scope
          self.nombre = self.c_nombre
          self.institucion = c_institucion
        rescue  # Por si era un find normalito, trato de busacr el usuario
          u = usuario
          self.nombre = "#{u.grado_academico} #{u.nombre} #{u.apellido}".strip
          self.correo = u.email
          self.institucion = u.institucion
        end
      end

    else  # Por si no esta el usuario_id
      begin  # Trato de ver si venia de un scope
        self.nombre = self.c_nombre
        self.institucion = c_institucion
      end
    end
  end
end
