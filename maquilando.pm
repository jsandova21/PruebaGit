#!/usr/bin/perl -w

# print "content-type:text/html\n\n";
###################
#Sistema:Sistema Control de Operaciones
#Nombre:Maquilando.pm
#Descripcion:Modulo Principal del Sistema.
#Autor:Joel Sandoval
#Fecha: 2/4/2022
####################
#-----------------------------------------------------
#Librerias Requerida:
# use base 'CGI::Application';
# use CGI::Session;
# use DBI;
# DBD
# HTML::Template
#-----------------------------------------------------
package Maquilando;
use base 'CGI::Application';
use CGI::Session;
use Win32::IPConfig;
use Sub_basedatos;
use Sub_combos;
use Sub_comunes;
use Sub_query;
use Sub_manejo_archivos;
use Sub_validacion;
require qw(Configuracion.pl); #IMPORTA VARIABLES ($ruta,$basedatos,$host,$port...)
#-----------------------------------------------------
#RUTINA DE CONFIGURACION
#-----------------------------------------------------
sub setup {
	$self = shift;
	$self -> start_mode('mode0');
	$self -> mode_param('rm');
	$self -> run_modes(
		#----------Mode ---------#
		#---Maquilando Diseños----
		'mode0' => 'crear_sesion',
		'mode1' => 'inicio',		
		'mode2' => 'datos_prenda',
		'mode3' => 'cargar_operaciones',
		'mode4' => 'modificar',
		'mode5' => 'control_diario',
		'mode6' => 'consultas',
		'mode7' => 'efectuado',
		'mode8' => 'resumen_efectuado'
		#---------------------------------------------------------------
	);
}
#-------------------------------------------------------------------------------------
#**INICIO MODULO DE MAQUILANDO DISEÑOS*******
#-------------------------------------------------------------------------------------
sub crear_sesion {       #mode0
#----------------------------------------------------------------
    $self=shift;
    $query=$self->query();
    #------------------Crear Sesion----------------#
    ###########para la version 4.20  #########
    $session = new CGI::Session(undef, undef, {Directory=>'/tmp'});
    $cookie = $query->cookie( -name   => $session->name, -value  => $session->id );
    $self  -> header_props (-cookie=>[$cookie]);
    CGI::Session->name("SID");
    $session -> expire('+12h');
#------------------------------ipconfig-------------------------------------
	my $host = shift || Win32::NodeName;
	my $ipconfig = Win32::IPConfig->new($host)
		or die "Unable to connect to $host\n";
	for my $adapter ($ipconfig->get_configured_adapters) {
		my @ipaddresses = $adapter->get_ipaddresses;
		for (0..@ipaddresses-1) {
			$direccion_ip=$ipaddresses[$_];
		}
	}
#-------------------------------------------------------------------
    $template=$self ->load_tmpl('inicio.html');
	$template -> param (ACCESO => 1,INGRESAR => 1,ROL1 => 1);
    return	$template -> output;
}
#-------------------------------------------------------------------
sub inicio {			#mode1 pantalla=>inicio
#-------------------------------------------------------------------
	($session)=&Sub_comunes::recuperar_session;
	my $boton=$self->query->param('boton');
	my $oper=$self->query->param('oper');
	my $usuario=$self->query->param('usuario');
	my $clave=$self->query->param('clave');
	Sub_comunes::guardar_oper($session,$oper);
	
    if ($boton eq "Ingresar") {
		$template=$self ->load_tmpl('inicio.html');
		if($usuario eq ""){
				$template -> param (ACCESO => 1,INGRESAR => 1,ROL1 => 1);
				$template -> param(var_men => "Debe ingresar usuario");
		}else{
			($rol)=&Sub_query::buscar_rol($usuario);
			if($rol eq ""){
				$template -> param (ACCESO => 1,INGRESAR => 1,ROL1 => 1);
				$template -> param(var_men => "usuario no existe");
			}else{
				if($rol<3){
					$template -> param (ACCESO => 1,CREAR_USR => 1,var_usuario => $usuario,ROL1 => 1);
				}else{
					$template -> param (OPERACIONES => 1,ROL3 => 1);
					Sub_comunes::guardar_usuario($session,$usuario,$clave2,$rol);
					$template=&Sub_combos::cargar_oper1($template,$rol2);
				}
			}
		}
	}elsif($boton eq "Acceder") {
		$template=$self ->load_tmpl('inicio.html');
		($usuario2,$clave2,$rol2)=&Sub_query::buscar_usuario($usuario,$clave);
		if($clave2 eq ""){
			$template -> param (ACCESO => 1,CREAR_USR => 1,var_usuario => $usuario);
			$template -> param(var_men => "clave invalida");
		}else{
			if($rol2<3){$template -> param (ROL1 => 1);}else{$template -> param (ROL3 => 1);}
			$template -> param (OPERACIONES => 1);
			Sub_comunes::guardar_usuario($session,$usuario2,$clave2,$rol2);
			$template=&Sub_combos::cargar_oper1($template,$rol2);
		}
	}elsif($boton eq "Recuperar"){
		$template=$self ->load_tmpl('inicio.html');
		($usuario2,$clave2,$rol2)=&Sub_query::buscar_clave($usuario);
		$template -> param (ACCESO => 1,CREAR_USR => 1,var_usuario => $usuario,var_men => "Su clave es: $clave2");
	}elsif($boton eq "Siguiente"){
		($usuario,$clave,$rol)=Sub_comunes::recuperar_usuario($session);
		if ($oper eq "1Inventario") {
			$template=$self ->load_tmpl('datos_prenda.html');
			$template -> param (INVENTARIO => 1);
			unlink ("c:/Apache24/htdocs/datos_operaciones_$usuario.txt");
		}elsif ($oper eq "2Tiempos(SAM)") {
			$template=$self ->load_tmpl('cargar_operaciones.html');
			$template -> param (OPERACIONES => 1,TIEMPOS=>1);
			$template=&Sub_query::cargar_referencia2($prenda,$template);
			unlink ("c:/Apache24/htdocs/datos_operaciones_$usuario.txt");
		}elsif  ($oper eq "3Control_Diario"){
			unlink ("c:/Apache24/htdocs/control_diario_$usuario.txt");
			unlink ("c:/Apache24/htdocs/totales_crl_diario_$usuario.txt");
			$template=$self ->load_tmpl('control_diario.html');
			$template -> param (CONTROL_DIARIO => 1,BOTON_CTRL_DRIO => 1);
			if($rol eq "3"){$template -> param (ROL3 => 1,var_operario=>$usuario);}else{$template -> param (OPER_CONTROL => 1);}
			$template=&Sub_query::cargar_referencia2($prenda,$template);
			$template=&Sub_query::cargar_operarios($noperario,$template);
		}elsif ($oper eq "4Consultar") {
			$template=$self ->load_tmpl('consultas.html');
			$template -> param (CONSULTAR => 1);
			$template=&Sub_query::cargar_operarios($noperario,$template);
		}elsif ($oper eq "5Cons_Mod_Inv") {
			$template=$self ->load_tmpl('datos_prenda.html');
			$template=&Sub_query::cargar_referencia2($prenda,$template);
			$template -> param (CONS_MOD => 1,var_modificar => 'MODIFICAR');
			unlink ("c:/Apache24/htdocs/datos_operaciones_$usuario.txt");
		}elsif ($oper eq "6Cons_Mod_Tiem") {
			$template=$self ->load_tmpl('cargar_operaciones.html');
			$template -> param (OPERACIONES => 1,CONS_MOD=>1,var_modificar => 'MODIFICAR');
			$template=&Sub_query::cargar_referencia2($prenda,$template);
			unlink ("c:/Apache24/htdocs/datos_operaciones_$usuario.txt");
		}else{ #($oper eq "7Cons_Mod_Ctrl_Drio")
			unlink ("c:/Apache24/htdocs/control_diario_$usuario.txt");
			unlink ("c:/Apache24/htdocs/totales_crl_diario_$usuario.txt");
			$template=$self ->load_tmpl('control_diario.html');
			$template -> param (CONTROL_DIARIO => 1,CONS_MOD => 1,OPER_CONS_MOD => 1,var_modificar => 'MODIFICAR');
			if($rol eq "3"){$template -> param (ROL3_CONS => 1,var_operario=>$usuario);}else{$template -> param (ROL1 => 1);}
			$template=&Sub_query::cargar_referencia2("",$template);
			$template=&Sub_query::cargar_operarios("",$template);
		}
	}else{
		$template=$self ->load_tmpl('inicio.html');
		$template -> param (ACCESO => 1,INGRESAR => 1,ROL1 => 1);
	}
	return	$template -> output;
}
#-------------------------------------------------------------------
sub datos_prenda {			#mode2 pantalla=>datos_prenda
#-------------------------------------------------------------------
	($session)=&Sub_comunes::recuperar_session;
	my $boton=$self->query->param('boton');
	$cliente=$self->query->param('cliente');
	$ref=$self->query->param('ref');
	$prenda=$self->query->param('prenda');
	$nprenda=$self->query->param('nprenda');
	$cant=$self->query->param('cant');
	my $oper=$self->query->param('oper');
	($usuario,$clave,$rol)=Sub_comunes::recuperar_usuario($session);
	
	$cliente=uc($cliente);
	$ref=uc($ref);
	$prenda=uc($prenda);
	
    if ($boton eq "Siguiente") {
        $template=$self ->load_tmpl('cargar_operaciones.html');
		$template -> param (OPERACIONES => 1,INVENTARIO => 1);
        Sub_comunes::guardar_datos_prenda($session,$template,$cliente,$ref,$prenda,$cant);
        $template=&Sub_comunes::mostrar_datos_prenda($template,$cliente,$ref,$prenda,$cant);
        &Sub_manejo_archivos::guardar_operaciones2($session,$template);
        $template=&Sub_manejo_archivos::mostrar_operaciones($session,$template);
    }elsif($boton eq "Modificar") {
        $template=$self ->load_tmpl('datos_prenda.html');
		$template -> param (CONS_MOD => 1,var_modificar => 'MODIFICAR');
        $template=&Sub_comunes::mostrar_datos_prenda($template,$cliente,$ref,$prenda,$cant);
        &Sub_query::modificar_datos_prenda($cliente,$ref,$prenda,$cant,$nprenda);
        $template -> param(var_men => "El inventario ha sido mofificado satisfactoriamente.");
		$template=&Sub_query::cargar_referencia2($nprenda,$template);		
		($nprenda,$prenda,$ref,$cliente,$cant)=&Sub_query::buscar_datos_prenda($nprenda);
        Sub_comunes::guardar_datos_prenda($session,$template,$cliente,$ref,$prenda,$cant);
        $template=&Sub_comunes::mostrar_datos_prenda($template,$cliente,$ref,$prenda,$cant);
    }elsif($boton eq "Salir"){
        $template=$self ->load_tmpl('inicio.html');
		$template -> param (OPERACIONES => 1);
		$template=&Sub_combos::cargar_oper1($template,$rol);
		if($rol eq "3"){$template -> param (ROL3 => 1);}else{$template -> param (ROL1 => 1);}
    }else{ #(CASO DE JAVA SCRIPT)
		$template=$self ->load_tmpl('datos_prenda.html');
		if($oper eq "1Inventario"){
			$template -> param (INVENTARIO => 1);
		}else{#if ($oper eq "5Cons_Mod_Inv") {
			$template -> param (CONS_MOD => 1,var_modificar => 'MODIFICAR');
		}
		$template=&Sub_query::cargar_referencia2($nprenda,$template);		
		($nprenda,$prenda,$ref,$cliente,$cant)=&Sub_query::buscar_datos_prenda($nprenda);
        Sub_comunes::guardar_datos_prenda($session,$template,$cliente,$ref,$prenda,$cant);
        $template=&Sub_comunes::mostrar_datos_prenda($template,$cliente,$ref,$prenda,$cant);
	}
	return	$template -> output;
}
#-------------------------------------------------------------------
sub cargar_operaciones {			#mode3 pantalla=>cargar_operaciones
#-------------------------------------------------------------------
	($session)=&Sub_comunes::recuperar_session;
	$oper=$session -> param("oper");
	$boton=$self->query->param('boton');
	$borrar=$self->query->param('borrar');
	$doper=$self->query->param('doper');
	$doper2=$self->query->param('doper2');
	$sam=$self->query->param('sam');
	($usuario,$clave,$rol)=Sub_comunes::recuperar_usuario($session);
	if($sam=~/\,/){$sam=~s/(\,)/\./g;}
	$doper=uc($doper);
	$doper=~s/(\s+$)//g;
	$doper2=uc($doper2);  
	$doper2=~s/(\s+$)//g;  
	if($oper eq "1Inventario"){
		($cliente,$ref,$prenda,$cant)=&Sub_comunes::recup_datos_prenda($session,$template);
	}else{
		$nprenda=$self->query->param('prenda');	
		$noper=$self->query->param('doper');	
		$nclient=&Sub_query::buscar_ncliente($nprenda);
		($nprenda,$prenda,$ref,$cliente,$cant)=&Sub_query::buscar_datos_prenda($nprenda);
		Sub_comunes::guardar_datos_prenda($session,$template,$cliente,$ref,$prenda,$cant);
	}
	
    my $archivo="c:/Apache24/htdocs/datos_operaciones_$usuario.txt";
        
    if ($boton eq "Guardar") {
        $template=$self ->load_tmpl('cargar_operaciones.html');
		if($oper eq "1Inventario"){
			$template -> param (GUARDAR => 1,INVENTARIO => 1);
		}else{#if ($oper eq "2Tiempos(SAM)") {
			$template -> param (GUARDAR => 1,TIEMPOS=>1);
			$template=&Sub_query::cargar_referencia2($nprenda,$template);
		}
        $template=&Sub_comunes::mostrar_datos_prenda($template,$cliente,$ref,$prenda,$cant);
        $template=&Sub_manejo_archivos::mostrar_operaciones2($session,$template);
        &Sub_query::guardar_proceso($session);
        $template -> param(var_men => "La Operaci&oacute;n ha sido almacenada satisfactoriamente.");
		
	}elsif ($boton eq "Modificar") {
        $template=$self ->load_tmpl('cargar_operaciones.html');
		# $doperacion=&Sub_query::buscar_doperacion($noper);
		$template -> param (OPERACIONES => 1,var_modificar => 'MODIFICAR',CONS_MOD => 1,var_sam => $sam,var_doper2 => "$doper2");
		$template=&Sub_query::cargar_referencia2($nprenda,$template);
        $template=&Sub_comunes::mostrar_datos_prenda($template,$cliente,$ref,$prenda,$cant);
		if(($doper2 eq "") and ($sam eq "")){
			$template -> param(var_men => "Debe ingresar un Nombre de Operacion y/o SAM a modifivar");
		}else{
			&Sub_query::modificar_sam($session,$doper,$sam,$doper2);
			$template -> param(var_men => "La Operaci&oacute;n ha sido modificada satisfactoriamente.");
		}
		$template=&Sub_query::cargar_operaciones($nclient,$nprenda,$noper,$template);
		Sub_query::buscar_datos_operacion($nprenda);
        $template=&Sub_manejo_archivos::mostrar_operaciones2($session,$template);
    
    }elsif ($boton eq "Agregar Otro") {
        $template=$self ->load_tmpl('cargar_operaciones.html');
		if($oper eq "1Inventario"){
			$template -> param (OPERACIONES => 1,INVENTARIO => 1);
		}elsif ($oper eq "6Cons_Mod_Tiem") {
			$template -> param (OPERACIONES => 1,var_modificar => 'MODIFICAR',CONS_MOD => 1);
			$template=&Sub_query::cargar_referencia2($nprenda,$template);
		}else{#if ($oper eq "2Tiempos(SAM)") {
			$template -> param (OPERACIONES => 1,TIEMPOS=>1);
			$template=&Sub_query::cargar_referencia2($nprenda,$template);
		}
        $template=&Sub_comunes::mostrar_datos_prenda($template,$cliente,$ref,$prenda,$cant);
		if($doper eq "" or $sam eq ""){
			$template -> param(var_men => "Debe ingresar Nombre y SAM de la Operacion");
			$template -> param (var_doper => $doper,var_sam => $sam);
			$template=&Sub_manejo_archivos::mostrar_operaciones($session,$template);
		}else{
			$costo=(($sam*$cant)*122);
			$unidad=($sam*122);
			&Sub_manejo_archivos::guardar_operaciones($doper,$coper,$sam,$costo,$unidad,$session);
			$template=&Sub_manejo_archivos::mostrar_operaciones($session,$template);
		}
    }elsif ($borrar>0) {#Eliminar
        $template=$self ->load_tmpl('cargar_operaciones.html'); 
		if($oper eq "1Inventario"){
			$template -> param (OPERACIONES => 1,INVENTARIO => 1);
		}elsif ($oper eq "6Cons_Mod_Tiem") {
			$template -> param (OPERACIONES => 1,var_modificar => 'MODIFICAR',CONS_MOD => 1);
			$template=&Sub_query::cargar_referencia2($nprenda,$template);
		}else{#if ($oper eq "2Tiempos(SAM)") {
			$template -> param (OPERACIONES => 1,TIEMPOS=>1);
			$template=&Sub_query::cargar_referencia2($nprenda,$template);
		}
        $lin=$borrar;
        $template=&Sub_comunes::mostrar_datos_prenda($template,$cliente,$ref,$prenda,$cant);
        &Sub_manejo_archivos::eliminar_linea_datos($lin,$archivo,$session);
        $template=&Sub_manejo_archivos::mostrar_operaciones($session,$template);
    }elsif ($boton eq "Regresar") {
        $template=$self ->load_tmpl('datos_prenda.html');
		$template -> param (INVENTARIO => 1);
        ($cliente,$ref,$prenda,$cant)=&Sub_comunes::recup_datos_prenda($session,$template);
        $template=&Sub_comunes::mostrar_datos_prenda($template,$cliente,$ref,$prenda,$cant);
    }elsif ($boton eq "Ingresar_Otro") {
		if($oper eq "1Inventario"){
			$template=$self ->load_tmpl('datos_prenda.html');
			$template -> param (INVENTARIO => 1);
		}else{#if ($oper eq "2Tiempos(SAM)") {
			$template=$self ->load_tmpl('cargar_operaciones.html'); 
			$template -> param (OPERACIONES => 1,TIEMPOS=>1);
			$template=&Sub_query::cargar_referencia2($nprenda,$template);
		}
		unlink ("c:/Apache24/htdocs/datos_operaciones_$usuario.txt");
    }elsif($boton eq "Salir"){
        $template=$self ->load_tmpl('inicio.html');
		$template -> param (OPERACIONES => 1);
		if($rol eq "3"){$template -> param (ROL3 => 1);}else{$template -> param (ROL1 => 1);}
		$template=&Sub_combos::cargar_oper1($template,$rol);
    }else{ #(CASO DE JAVA SCRIPT)
        $template=$self ->load_tmpl('cargar_operaciones.html');
		($nprenda,$prenda,$ref,$cliente,$cant)=&Sub_query::buscar_datos_prenda($nprenda);
		$template=&Sub_query::cargar_operaciones($nclient,$nprenda,$noper,$template);
        Sub_comunes::guardar_datos_prenda($session,$template,$cliente,$ref,$prenda,$cant);
        $template=&Sub_comunes::mostrar_datos_prenda($template,$cliente,$ref,$prenda,$cant);
		Sub_query::buscar_datos_operacion($nprenda);
		if($oper eq "1Inventario"){
			$template -> param (OPERACIONES => 1,INVENTARIO => 1);
			$template=&Sub_manejo_archivos::mostrar_operaciones($session,$template);
		}elsif ($oper eq "6Cons_Mod_Tiem") {
			$sam2=&Sub_query::buscar_sam($doper);
			$doperacion=&Sub_query::buscar_doperacion($noper);
			$template -> param (OPERACIONES => 1,var_modificar => 'MODIFICAR',CONS_MOD => 1,var_sam => $sam2,var_doper2 => "$doperacion");
			$template=&Sub_query::cargar_referencia2($nprenda,$template);
			$template=&Sub_manejo_archivos::mostrar_operaciones2($session,$template);
		}else{#if ($oper eq "2Tiempos(SAM)") {
			$template -> param (OPERACIONES => 1,TIEMPOS=>1);
			$template=&Sub_query::cargar_referencia2($nprenda,$template);
			$template=&Sub_manejo_archivos::mostrar_operaciones($session,$template);
		}
	}
	return	$template -> output;
}
#------------------------------------------------------------------
sub control_diario {			#mode5 pantalla=>control_diario
#-------------------------------------------------------------------
	($session)=&Sub_comunes::recuperar_session;
	
	my $boton=$self->query->param('boton');
	$oper=$session -> param("oper");
	$borrar=$self->query->param('borrar');
	$des=$self->query->param('des');
	$has=$self->query->param('has');
	$fecha=$self->query->param('fecha');
	$hdes=$self->query->param('hdes');
	$hhas=$self->query->param('hhas');
	$nprenda=$self->query->param('prenda');
	$noper=$self->query->param('doper');
	$noperario=$self->query->param('operario');
	$noperario2=$self->query->param('operario2');
	$noperario3=$self->query->param('operario3');
	$cantidad=$self->query->param('cantidad');
	$monto=$self->query->param('monto');
	$horas=$self->query->param('horas');
	($usuario,$clave,$rol)=Sub_comunes::recuperar_usuario($session);
	
	($nprenda,$prenda,$ref,$cliente,$cant)=&Sub_query::buscar_datos_prenda($nprenda);
	Sub_comunes::guardar_datos_prenda($session,$template,$cliente,$ref,$prenda,$cant);
	$nclient=&Sub_query::buscar_ncliente($nprenda);
	$doper=&Sub_query::buscar_doperacion($noper);
	$doper=~s/(\s+$)//g;
	$doperario=&Sub_query::buscar_doperario($noperario);
	$doperario=~s/(\s+$)//g;
	$doperario="($doperario)";
	$cant_total=&Sub_query::buscar_cant_total($noper);
            
    my $archivo="c:/Apache24/htdocs/control_diario_$usuario.txt";
	
    if ($boton eq "Guardar") {
        $template=$self ->load_tmpl('control_diario.html');
		$template -> param (GUARDAR => 1,var_operario => "$doperario");
        &Sub_query::guardar_control_diario($session);
		$template=&Sub_manejo_archivos::mostrar_control_diario($session,$template);
        $template -> param(var_men => "La Operaci&oacute;n ha sido almacenada satisfactoriamente.");
	}elsif ($boton eq "Modificar") {
        $template=$self ->load_tmpl('control_diario.html');
		$template -> param (CONTROL_DIARIO => 1,OPER_CONS_MOD => 1,var_modificar => 'MODIFICAR',OPER_CONS_MOD => 1,CONS_MOD => 1,var_modificar => 'MODIFICAR',var_operario => "$doperario",var_des => "$des",var_has => "$has",var_hdes => "$hdes",var_hhas => "$hhas");
		if($rol eq "3"){$template -> param (ROL3_CONS => 1,var_operario=>$usuario);}else{$template -> param (ROL1 => 1);}
		$template=&Sub_query::cargar_referencia2($nprenda,$template);
        $template=&Sub_comunes::mostrar_datos_prenda($template,$cliente,$ref,$prenda,$cant);
        @error=&Sub_validacion::validar_control_diario($fecha,$nclient,$nprenda,$noper,$noperario,$noperario2,$cantidad,$doper,$monto,$horas,$hdes,$hhas,$noperario3);
		if(@error){
			$template=&Sub_validacion::mostrar_errores($template,@error);
			$template -> param (var_fecha => "$fecha",var_monto => "$monto",var_cantidad => $cantidad,var_horas => $horas,var_operario2 => $noperario2,var_operario => "$doperario",var_hdes => "$hdes",var_hhas => "$hhas");
			$template=&Sub_query::cargar_operarios($noperario,$template);	
			$template=&Sub_query::cargar_operaciones($nclient,$nprenda,$noper,$template);
			if ($doper eq "Pago_por_Arreglos_(horas)"){
				$template -> param (ARREGLO => 1);
				$template=&Sub_query::cargar_operarios2($noperario3,$template);
			}	
			if ($doper =~/horas/){$template -> param (HORAS => 1);}
			elsif ($doper eq "Cafetin_(monto)"){$template -> param (MONTO => 1);}
			else{$template -> param (CANTIDAD => 1);}
			&Sub_manejo_archivos::totales_crl_diario($session);
			$template=&Sub_manejo_archivos::mostrar_control_diario($session,$template);
		}else{
			$cant_resta2=&Sub_query::buscar_cant_resta($noper);
			$cantidad2=$session -> param("cantidad2");
			$diferencia=($cantidad-$cantidad2);
			$cant_resta=($cant_resta2+($diferencia*-1));
			$resta=$cant_resta;
			if($doper eq "Cafetin_(monto)" or $doper eq "Arreglos_(horas)" or $doper eq "Pago_por_Arreglos_(horas)" or $doper eq "Servicios_Varios_(horas)"){
				$otros=1;
				$sam=0;
				$cant_total=0;
				$resta=0;
				if($monto){$pago=$monto;$valor_unidad=0;$cantidad=0;}
				if($horas){$pago=(4500*$horas);$valor_unidad=4500;$cantidad=$horas;}
			}else{
				$otros=0;
				$sam=&Sub_query::buscar_sam($noper);
				$pago=(($sam*$cantidad)*122);
				$valor_unidad=($sam*122);
			}
			if(($resta=~/-/) and ($otros eq "0")){
				$template -> param(var_men => "Alerta la cantidad requerida para la operacion $doper a sido exedida");
			}
			$template -> param (var_fecha => "$fecha");
			$template=&Sub_query::cargar_operaciones($nclient,$nprenda,$noper,$template);
			$template=&Sub_query::cargar_operarios($noperario,$template);
			if ($doper eq "Pago_por_Arreglos_(horas)"){
				$template -> param (ARREGLO => 1);
				$template=&Sub_query::cargar_operarios2($noperario3,$template);
			}
			if ($doper =~/horas/){$template -> param (HORAS => 1,var_horas => $horas);}
			elsif ($doper eq "Cafetin_(monto)"){$template -> param (MONTO => 1,var_monto => "$pago");}
			else{$template -> param (CANTIDAD => 1,var_cantidad => "$cantidad");}
			&Sub_query::modificar_control_diario($session,$noperario,$nprenda,$nclient,$noper,$sam,$cantidad,$pago,$fecha,$valor_unidad,$resta,$cant_total,$hdes,$hhas,$noperario3);
			&Sub_manejo_archivos::modificar_control_diario($session,$archivo,$noperario,$nprenda,$nclient,$noper,$sam,$cantidad,$pago,$fecha,$valor_unidad,$resta,$cant_total,$hdes,$hhas,$noperario3);	
			$template=&Sub_manejo_archivos::mostrar_control_diario($session,$template);
			&Sub_manejo_archivos::totales_crl_diario($session);
			$template -> param(var_men => "La Operaci&oacute;n ha sido modificada satisfactoriamente.");
		}
    }elsif ($boton eq "Eliminar") {
        $template=$self ->load_tmpl('control_diario.html');
		$lin=$lin2=$session -> param("lin2");
		$nnomina=$session -> param("nnomina");
		$cantidad2=$session -> param("cantidad2");
		$cant_resta2=&Sub_query::buscar_cant_resta($noper);
		$resta=($cantidad2+$cant_resta2);
		Sub_query::modificar_cant_resta($noper,$resta);
		&Sub_manejo_archivos::eliminar_linea_datos($lin,$archivo,$session);
        &Sub_query::eliminar_reg_ctrol_diario($nnomina);
		if ($doper =~/horas/){$template -> param (HORAS => 1);}
		elsif ($doper eq "Cafetin_(monto)"){$template -> param (MONTO => 1);}
		else{$template -> param (CANTIDAD => 1);}
		$template -> param (CONTROL_DIARIO => 1,OPER_CONS_MOD => 1,var_modificar => 'MODIFICAR',OPER_CONS_MOD => 1,CONS_MOD => 1,var_modificar => 'MODIFICAR',var_operario => "$doperario",var_des => "$des",var_has => "$has",var_hdes => "$hdes",var_hhas => "$hhas");
		if($rol eq "3"){$template -> param (ROL3_CONS => 1,var_operario=>$usuario);}else{$template -> param (ROL1 => 1);}
		$template=&Sub_query::cargar_referencia2($nprenda,$template);
        $template=&Sub_comunes::mostrar_datos_prenda($template,$cliente,$ref,$prenda,$cant);
        $template=&Sub_query::cargar_operaciones($nclient,$nprenda,$noper,$template);
		if ($doper eq "Pago_por_Arreglos_(horas)"){
			$template -> param (ARREGLO => 1);
			$template=&Sub_query::cargar_operarios2($noperario3,$template);
		}
        $template=&Sub_query::cargar_operarios($noperario,$template);
		unlink ("c:/Apache24/htdocs/control_diario_$usuario.txt");
		unlink ("c:/Apache24/htdocs/totales_crl_diario_$usuario.txt");
		&Sub_query::buscar_control_diario($noperario,$des,$has,$session,$template);
        &Sub_manejo_archivos::totales_crl_diario($session);
        $template=&Sub_manejo_archivos::mostrar_control_diario($session,$template);
    }elsif ($boton eq "Agregar Otro") {
        $template=$self ->load_tmpl('control_diario.html');
		$template -> param (CONTROL_DIARIO => 1,var_hdes => "$hdes",var_hhas => "$hhas",var_operario => "$doperario");
		if ($oper eq "3Control_Diario") {
			$template -> param (BOTON_CTRL_DRIO => 1);
			if($rol eq "3"){$template -> param (ROL3 => 1,var_operario=>$usuario);}else{$template -> param (OPER_CONTROL => 1);}
		}else{#if ($oper eq "7Cons_Mod_Ctrl_Drio") {
			$template -> param (OPER_CONS_MOD => 1,CONS_MOD => 1,var_modificar => 'MODIFICAR',var_operario => "$doperario",var_des => "$des",var_has => "$has");
			if($rol eq "3"){$template -> param (ROL3_CONS => 1,var_operario=>$usuario);}else{$template -> param (ROL1 => 1);}
		}
		$template=&Sub_query::cargar_referencia2($nprenda,$template);
        $template=&Sub_comunes::mostrar_datos_prenda($template,$cliente,$ref,$prenda,$cant);
		
        @error=&Sub_validacion::validar_control_diario($fecha,$nclient,$nprenda,$noper,$noperario,$noperario2,$cantidad,$doper,$monto,$horas,$hdes,$hhas,$noperario3);
		if(@error){
			$template=&Sub_validacion::mostrar_errores($template,@error);
			$template -> param (var_fecha => "$fecha",var_monto => "$monto",var_cantidad => $cantidad,var_horas => $horas,var_operario2 => $noperario2,var_operario => "doperario",var_hdes => "$hdes",var_hhas => "$hhas");
			$template=&Sub_query::cargar_operarios($noperario,$template);	
			$template=&Sub_query::cargar_operaciones($nclient,$nprenda,$noper,$template);
			if ($doper eq "Pago_por_Arreglos_(horas)"){
				$template -> param (ARREGLO => 1);
				$template=&Sub_query::cargar_operarios2($noperario3,$template);
			}	
			if ($doper =~/horas/){$template -> param (HORAS => 1);}
			elsif ($doper eq "Cafetin_(monto)"){$template -> param (MONTO => 1);}
			else{$template -> param (CANTIDAD => 1);}
			$template=&Sub_manejo_archivos::mostrar_control_diario($session,$template);
			&Sub_manejo_archivos::totales_crl_diario($session);
		}else{
			$otros=0;
			$cant_resta=&Sub_query::buscar_cant_resta($noper);
			$cant_dia=&Sub_manejo_archivos::suma_txt2($archivo,4,2,$noper,$cantidad);
			$resta=($cant_resta-$cant_dia);
			if($doper eq "Cafetin_(monto)" or $doper eq "Arreglos_(horas)" or $doper eq "Pago_por_Arreglos_(horas)" or $doper eq "Servicios_Varios_(horas)"){
				$otros=1;
				$sam=0;
				$cant_total=0;
				$resta=0;
				if($monto){$pago=$monto;$valor_unidad=0;$cantidad=0;}
				if($horas){$pago=(4500*$horas);$valor_unidad=4500;$cantidad=$horas;}
			}else{
				$sam=&Sub_query::buscar_sam($noper);
				$pago=(($sam*$cantidad)*122);
				$valor_unidad=($sam*122);
			}
			if(($resta=~/-/) and ($otros eq "0")){
				$template -> param(var_men => "Alerta la cantidad requerida para la operacion $doper a sido exedida");
			}
			$template -> param (var_fecha => "$fecha",var_monto => "",var_cantidad => "",var_horas => "");
			$template=&Sub_query::cargar_operaciones($nclient,$nprenda,$noper,$template);
			if($noperario2){$noperario=&Sub_query::guardar_operario($noperario2,$noperario2);}
			$template=&Sub_query::cargar_operarios($noperario,$template);
			if ($doper eq "Pago_por_Arreglos_(horas)"){
				$template -> param (ARREGLO => 1);
				$template=&Sub_query::cargar_operarios2($noperario3,$template);
			}
			if ($doper =~/horas/){$template -> param (HORAS => 1);}
			elsif ($doper eq "Cafetin_(monto)"){$template -> param (MONTO => 1);}
			else{$template -> param (CANTIDAD => 1);}
			&Sub_manejo_archivos::guardar_control_diario($session,$noperario,$nprenda,$nclient,$noper,$sam,$cantidad,$pago,$fecha,$valor_unidad,$resta,$cant_total,$hdes,$hhas,$noperario3);
			&Sub_manejo_archivos::totales_crl_diario($session);			
			$template=&Sub_manejo_archivos::mostrar_control_diario($session,$template);
		}
    }elsif ($borrar>0) {#Eliminar
        $template=$self ->load_tmpl('control_diario.html');
		if ($oper eq "3Control_Diario") {
			$lin=$borrar;
			$template -> param (BOTON_CTRL_DRIO => 1,var_operario => "$doperario");
			if($rol eq "3"){$template -> param (ROL3 => 1,var_operario=>$usuario);}else{$template -> param (OPER_CONTROL => 1);}
			&Sub_manejo_archivos::eliminar_linea_datos($lin,$archivo,$session);
		}else{#if ($oper eq "7Cons_Mod_Ctrl_Drio") {
			($nnomina,$lin2) = split(/\-/,$borrar);
			$session -> param("nnomina",$nnomina);
			$session -> param("lin2",$lin2);
			$template -> param (OPER_CONS_MOD => 1,CONS_MOD => 1,var_modificar => 'MODIFICAR',var_operario => "$doperario",var_des => "$des",var_has => "$has");
			if($rol eq "3"){$template -> param (ROL3_CONS => 1,var_operario=>$usuario);}else{$template -> param (ROL1 => 1);}
			($nprenda,$cliente,$ref,$prenda,$cant,$nclient,$noper,$doper,$noperario,$fecha,$hdes,$hhas,$monto,$horas,$cantidad,$sam,$resta,$noperario3,$nnomina2)=&Sub_query::buscar_tnomina($nnomina,$session);
			$session -> param("cantidad2",$cantidad);
			$session -> param("nnomina2",$nnomina2);
		}
		if ($doper =~/horas/){$template -> param (HORAS => 1);}
		elsif ($doper eq "Cafetin_(monto)"){$template -> param (MONTO => 1);}
		else{$template -> param (CANTIDAD => 1);}
		$template -> param (CONTROL_DIARIO => 1,var_fecha => "$fecha",var_monto => "$monto",var_cantidad => "$cantidad",var_horas => "$horas",var_hdes => "$hdes",var_hhas => "$hhas");
		$template=&Sub_query::cargar_referencia2($nprenda,$template);
        $template=&Sub_comunes::mostrar_datos_prenda($template,$cliente,$ref,$prenda,$cant);
        $template=&Sub_query::cargar_operaciones($nclient,$nprenda,$noper,$template);
		if ($doper eq "Pago_por_Arreglos_(horas)"){
			$template -> param (ARREGLO => 1);
			$template=&Sub_query::cargar_operarios2($noperario3,$template);
		}
        $template=&Sub_query::cargar_operarios($noperario,$template);
        &Sub_manejo_archivos::totales_crl_diario($session);
        $template=&Sub_manejo_archivos::mostrar_control_diario($session,$template);
    }elsif ($boton eq "Salir") {
        $template=$self ->load_tmpl('inicio.html');
		$template -> param (OPERACIONES => 1);
		if($rol eq "3"){$template -> param (ROL3 => 1);}else{$template -> param (ROL1 => 1);}
		$template=&Sub_combos::cargar_oper1($template,$rol);
		unlink ("c:/Apache24/htdocs/control_diario_$usuario.txt");
		unlink ("c:/Apache24/htdocs/totales_crl_diario_$usuario.txt");
    }elsif ($boton eq "Ing_Otro") {
		my $archivo="c:/Apache24/htdocs/control_diario_$usuario.txt";
		unlink ("c:/Apache24/htdocs/control_diario_$usuario.txt");
		$template=$self ->load_tmpl('control_diario.html');
		if ($oper eq "3Control_Diario") {
			$template -> param (BOTON_CTRL_DRIO => 1,var_operario => "");
			if($rol eq "3"){$template -> param (ROL3 => 1,var_operario=>$usuario);}else{$template -> param (OPER_CONTROL => 1);}
		}else{#if ($oper eq "7Cons_Mod_Ctrl_Drio") {
			$template -> param (CONTROL_DIARIO => 1,CONS_MOD => 1,OPER_CONS_MOD => 1,var_modificar => 'MODIFICAR',var_operario => "$doperario",var_des => "$des",var_has => "$has");
			if($rol eq "3"){$template -> param (ROL3_CONS => 1,var_operario=>$usuario);}else{$template -> param (ROL1 => 1);}
		}
		$template=&Sub_query::cargar_referencia2($nprenda,$template);
		$template=&Sub_query::cargar_operarios("",$template);
    }else{ #(CASO DE JAVA SCRIPT)
        $template=$self ->load_tmpl('control_diario.html');
		$template -> param (CONTROL_DIARIO => 1,var_fecha => "$fecha",var_monto => "$monto",var_cantidad => "$cantidad",var_horas => "$horas",var_hdes => "$hdes",var_hhas => "$hhas");
		if ($oper eq "3Control_Diario") {
			$template -> param (BOTON_CTRL_DRIO => 1,var_operario => "$doperario");
			if($rol eq "3"){$template -> param (ROL3 => 1,var_operario=>$usuario);}else{$template -> param (OPER_CONTROL => 1);}
			$template=&Sub_query::cargar_referencia2($nprenda,$template);
			if($noperario2){$noperario=&Sub_query::guardar_operario($noperario2,$noperario2);}
		}else{#if ($oper eq "7Cons_Mod_Ctrl_Drio") {
			$template -> param (OPER_CONS_MOD => 1,CONS_MOD => 1,var_modificar => 'MODIFICAR',var_operario => "$doperario",var_des => "$des",var_has => "$has");
			if($rol eq "3"){
				$template -> param (ROL3_CONS => 1,var_operario=>$usuario);
				$noperario=&Sub_query::buscar_noperario($usuario);
			}else{
				$template -> param (ROL1 => 1);
			}
			$template=&Sub_query::cargar_referencia2($nprenda,$template);
			unlink ("c:/Apache24/htdocs/control_diario_$usuario.txt");
			unlink ("c:/Apache24/htdocs/totales_crl_diario_$usuario.txt");
			&Sub_query::buscar_control_diario($noperario,$des,$has,$session,$template);
		}
        $template=&Sub_comunes::mostrar_datos_prenda($template,$cliente,$ref,$prenda,$cant);
        $template=&Sub_query::cargar_operaciones($nclient,$nprenda,$noper,$template);
		if ($doper eq "Pago_por_Arreglos_(horas)"){
			$template -> param (ARREGLO => 1);
			$template=&Sub_query::cargar_operarios2($noperario3,$template);
		}
		if ($doper =~/horas/){$template -> param (HORAS => 1);}
		elsif ($doper eq "Cafetin_(monto)"){$template -> param (MONTO => 1);}
		else{$template -> param (CANTIDAD => 1);}
        $template=&Sub_query::cargar_operarios($noperario,$template);
        &Sub_manejo_archivos::totales_crl_diario($session);
        $template=&Sub_manejo_archivos::mostrar_control_diario($session,$template);
    }
	return	$template -> output;
}
#-------------------------------------------------------------------
sub consultas {			#mode6 pantalla=>consulta
#-------------------------------------------------------------------
	($session)=&Sub_comunes::recuperar_session;
	
	$boton=$self->query->param('boton');
	$noperario=$self->query->param('operario');
	$des=$self->query->param('des');
	$has=$self->query->param('has');
	($usuario,$clave,$rol)=Sub_comunes::recuperar_usuario($session);
	
	&Sub_comunes::guardar_datos_consulta($session,$template,$noperario,$des,$has);
	
    if ($boton eq "Aceptar") {
		@error=&Sub_validacion::validar_consulta($des,$has,$noperario);
		if(!@error){
			$template=$self ->load_tmpl('efectuado.html');
			$template=&Sub_query::mostrar_efectuado($des,$has,$noperario,$template);
		}else{
			$template=$self ->load_tmpl('consultas.html');
			$template -> param (CONSULTAR => 1);
			$template=&Sub_validacion::mostrar_errores($template,@error);
			$template -> param (var_des => "$des",var_has => "$has");
			$template=&Sub_query::cargar_operarios($noperario,$template);
		}
        
    }elsif ($boton eq "Salir") {
        $template=$self ->load_tmpl('inicio.html');
		$template -> param (OPERACIONES => 1);
		if($rol eq "3"){$template -> param (ROL3 => 1);}else{$template -> param (ROL1 => 1);}
		$template=&Sub_combos::cargar_oper1($template,$rol);

    }else{ #(CASO DE JAVA SCRIPT)
		$template=$self ->load_tmpl('consultas.html');
		$template -> param (CONSULTAR => 1);
		$template -> param (var_des => "$des",var_des => "$has");
		$template=&Sub_query::cargar_operarios($noperario,$template);
    }
	return	$template -> output;
}
#-------------------------------------------------------------------
sub efectuado {			#mode7 pantalla=>efectuado
#-------------------------------------------------------------------
	($session)=&Sub_comunes::recuperar_session;
	
	my $boton=$self->query->param('boton');
    my $noper=$self->query->param('detalle');
	$session -> param("noper",$noper);
	($usuario,$clave,$rol)=Sub_comunes::recuperar_usuario($session);
	($noperario,$des,$has)=&Sub_comunes::recup_datos_consulta($session,$template);
    
    if ($boton eq "Regresar") {
		$template=$self ->load_tmpl('consultas.html');
		$template -> param (CONSULTAR => 1);
		$template=&Sub_validacion::mostrar_errores($template,@error);
		$template=&Sub_query::cargar_operarios("",$template);
    }elsif($boton eq "Salir"){
        $template=$self ->load_tmpl('inicio.html');
		$template -> param (OPERACIONES => 1);
		if($rol eq "3"){$template -> param (ROL3 => 1);}else{$template -> param (ROL1 => 1);}
		$template=&Sub_combos::cargar_oper1($template,$rol);
    }else{ #Detalle del registro
		$template=$self ->load_tmpl('resumen_efectuado.html');
		$template=&Sub_query::mostrar_detalle_efectuado($noper,$des,$has,$session,$template);
		$doperario=&Sub_query::buscar_doperario($noper);
		$doperario=~s/(\s+$)//g;
		$template -> param (var_operario => "($doperario)");
		# $template -> param (PAGAR => 1);
		$template -> param (SALIR => 1);
	}
	return	$template -> output;
}
#-------------------------------------------------------------------
sub resumen_efectuado {			#mode8 pantalla=>resumen_efectuado
#-------------------------------------------------------------------
	($session)=&Sub_comunes::recuperar_session;
	
	my $boton=$self->query->param('boton');
	$noper=$session -> param("noper");
	($usuario,$clave,$rol)=Sub_comunes::recuperar_usuario($session);
	($noperario,$des,$has)=&Sub_comunes::recup_datos_consulta($session,$template);
	
    if ($boton eq "Pagar") {
		$template=$self ->load_tmpl('resumen_efectuado.html');
		$template=&Sub_query::mostrar_detalle_efectuado($noper,$des,$has,$session,$template);
		Sub_query::pagar_quincena($noper,$des,$has);
		$template -> param (SALIR => 1);
		# $template -> param (SALIR => 1,var_men => "El pago ha sido almacenado satisfactoriamente.");
    }elsif ($boton eq "Regresar") {
		$template=$self ->load_tmpl('efectuado.html');
		$template=&Sub_query::mostrar_efectuado($des,$has,$noperario,$template);
    }else{ #Si el boton es Salir
        $template=$self ->load_tmpl('inicio.html');
		$template -> param (OPERACIONES => 1);
		if($rol eq "3"){$template -> param (ROL3 => 1);}else{$template -> param (ROL1 => 1);}
		$template=&Sub_combos::cargar_oper1($template,$rol);
    }
	return	$template -> output;
}
#-------------------------------------------------------------------------------------
#**FIN MODULO DE MAQUILANDO DISEÑOS*******
#-------------------------------------------------------------------------------------

1;
