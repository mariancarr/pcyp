package c

import (
	"math/rand"
	"time"
)

type Package struct {
	contenido 		string
}

type TipoSolicitud string

const (
	Alta TipoSolicitud = "Alta"
	Baja TipoSolicitud = "Baja"
)

type solicitud struct {
	canal 		chan Package
	tipo 		TipoSolicitud
}

func plataformaStream(canalInicio, canalConStreamer chan Package, solicitudes chan solicitud){
	var suscriptos []chan Package
	iniciado := false
	for{
		select{
		case solicitud := <- solicitudes:
			if solicitud.tipo == Alta{
				suscriptos = append(suscriptos, solicitud.canal)
				if !iniciado && len(suscriptos) == 3{
					canalInicio <- Package{}
					iniciado = true
				}
			}
			if solicitud.tipo == Baja{
					suscriptos = quitarCanal(suscriptos, solicitud.canal)
			}
		case paquete := <- canalConStreamer:
			for i:= range suscriptos{
				suscriptos[i] <- paquete
			}
		}
	}
}

func quitarCanal(suscriptos []chan Package, canal chan Package) []chan Package {
	for i, suscripto := range suscriptos {
		if suscripto == canal {
			copy(suscriptos[i:], suscriptos[i+1:])
			suscriptos[len(suscriptos)-1] = nil
			return suscriptos[:len(suscriptos)-1]
		}
	}
	return suscriptos
}

func streamer(canalInicio, canalPlataforma chan Package){
	// Espero a que lleguen las 3 subs para arrancar 
	<- canalInicio
	ticker := time.NewTicker(time.Duration(500) * time.Millisecond)
	defer ticker.Stop()
	for range ticker.C{
		canalPlataforma <- Package{contenido: "El salto del papu"}
	}
}

func suscriptor(canalConPlataforma chan solicitud){
	var canalParaRecibirActualizaciones chan Package = make(chan Package)
	canalConPlataforma <- solicitud{
		tipo: Alta,
		canal: canalParaRecibirActualizaciones,
	}
	cantidad := rand.Intn(10) + 1
	for i := 0; i < cantidad; i++ {
		paquete := <- canalParaRecibirActualizaciones
		print(paquete.contenido)
	}
	canalConPlataforma <- solicitud{
		tipo: Baja,
		canal: canalParaRecibirActualizaciones,
	}
}
