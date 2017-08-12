module BusquedasHelper

  # NPI
  def busquedas(iterador)
    opciones=''
    iterador.each do |valor, nombre|
      opciones+="<option value=\"#{valor}\">#{nombre}</option>"
    end
    opciones
  end

  # Filtros para los grupos icónicos en la búsqueda avanzada vista básica
  def radioGruposIconicos
    radios = ''
    columnas = 1

    iconos = Icono::Reinos+Icono::Animales+Icono::Plantas
    iconos.each do |taxon|  # Para tener los grupos ordenados
      ic = taxon.adicional
      # Para dejar el espacio despues de los reinos
      if columnas == 6
        radios << '<br \>'*3  # neta? >.>!
        columnas = 7
      end
      puts ic.nombre_comun_principal.inspect

      radios << "<label>"
      radios << radio_button_tag('id', taxon.id, false)
      radios << "<span title=\"#{ic.nombre_comun_principal}\" style=\"color:black;\" class=\"#{taxon.nombre_cientifico.parameterize}-ev-icon btn btn-xs btn-basica btn-title #{}\" id_icono=\"#{taxon.id}\"></span>"
      radios << "</label>"
      radios << '<br>' if columnas%6 == 0
      columnas+=1
    end

    "<div>#{radios}</div>"
  end

  # Filtros para Categorías de riesgo y comercio internacional
  def checkboxEstadoConservacion
    checkBoxes=''

    Catalogo.nom_cites_iucn_todos.each do |k, valores|
      checkBoxes << "<h6><strong>#{t(k)}</strong><h6>"
      valores.each do |edo|
        next if edo == 'Riesgo bajo (LR): Dependiente de conservación (cd)' # Esta no esta definida en IUCN, checar con Diana
        checkBoxes << "<label>"
        checkBoxes << check_box_tag('edo_cons[]', edo, false, :id => "edo_cons_#{edo.parameterize}")
        checkBoxes << "<span title = '#{t('cat_riesgo.' << edo.parameterize << '.nombre')}' class = 'btn btn-xs btn-basica btn-title'>"
        checkBoxes << "<i class = '#{edo.parameterize}-ev-icon'></i>"
        checkBoxes << "</span>"
        checkBoxes << "</label>"
      end
    end

    checkBoxes.html_safe
  end

  # Filtros para "Tipo de distribución" (nativa, endémica, shalalala)
  def checkboxTipoDistribucion
    checkBoxes = ''
    if I18n.locale.to_s == 'es-cientifico'
      TipoDistribucion::DISTRIBUCIONES.each do |tipoDist|
        next if TipoDistribucion::QUITAR_DIST.include?(tipoDist)
        checkBoxes << "<label>"
        checkBoxes << check_box_tag('dist[]', t('distribucion.' + tipoDist.gsub(' ', '_')), false, id: "dist_#{tipoDist}")
        checkBoxes << "<span title = '#{t('distribucion.' << tipoDist.gsub(' ', '_'))}' class='btn btn-xs btn-basica '>#{t('distribucion.' << tipoDist.gsub(' ', '_'))}</span>"
        checkBoxes << "</label>"
      end
    else
      TipoDistribucion::DISTRIBUCIONES_SOLO_BASICA.each do |tipoDist|
        checkBoxes << "<label>"
        checkBoxes << check_box_tag('dist[]', t('distribucion.' + tipoDist.gsub(' ', '_')), false, id: "dist_#{tipoDist}")
        checkBoxes << "<span title = '#{t('tipo_distribucion.' << tipoDist.parameterize << '.nombre')}' class = 'btn btn-xs btn-basica btn-title'>"
        checkBoxes << "<i class = '#{tipoDist.parameterize}-ev-icon'></i>"
        checkBoxes << "</span>"
        checkBoxes << "</label>"

      end
    end

    checkBoxes.html_safe
  end

  # Filtros para Estatus taxonómico
  def checkboxValidoSinonimo (busqueda=nil)
    checkBoxes = ''
    Especie::ESTATUS_BUSQUEDA.each do |e|

      checkBoxes += case busqueda
                      when "BBShow" then "<label class='checkbox-inline'>#{check_box_tag('estatus[]', e.first, false, :class => :busqueda_atributo_checkbox, :onChange => '$(".checkBoxesOcultos").empty();$("#panelValidoSinonimoBasica  :checked ").attr("checked",true).clone().appendTo(".checkBoxesOcultos");')} #{e.last}</label>"
                      else "<label> #{check_box_tag('estatus[]', e.first, false, id: "estatus_#{e.first}")} <span class = 'btn btn-xs btn-basica' title = #{e.last}>#{e.last}</span></label>"
                    end
    end
    checkBoxes.html_safe
  end

  # Filtros para "Especies prioritarias para la conservaciónEspecies prioritarias para la conservación"
  def checkboxPrioritaria
    checkBoxes = ''

    Catalogo::NIVELES_PRIORITARIAS.each do |prior|
      checkBoxes << '<label>'
      checkBoxes << check_box_tag('prior[]', prior, false, :id => "prior_#{prior.parameterize}")
      checkBoxes << "<span title = '#{t('prioritaria.' << prior.parameterize << '.nombre')}' class = 'btn btn-xs btn-basica btn-title' >"
      checkBoxes << "<i class = '#{prior.parameterize}-ev-icon'></i>"
      checkBoxes << '</span>'
      checkBoxes << '</label>'
    end

    checkBoxes.html_safe
  end

  # Si la búsqueda ya fue realizada y se desea generar un checklist, unicamente se añade un parametro extra y se realiza la búsqueda as usual
  def checklist(datos)
    if datos[:totales] > 0
      sin_page_per_page = datos[:request].split('&').map{|attr| attr if !attr.include?('pagina=')}
      peticion = sin_page_per_page.compact.join('&')
      peticion << "&por_pagina=#{datos[:totales]}&checklist=1"
    else
      ''
    end
  end
end
