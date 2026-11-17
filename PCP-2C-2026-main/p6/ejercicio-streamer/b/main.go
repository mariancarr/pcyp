package b

import "time"

type Package struct {
	contenido 		string
}

func plataformaStream(canalInicio, canalConStreamer chan Package, solicitudes chan chan Package){
	var suscriptos []chan Package
	for{
		select{
		case solicitud := <- solicitudes:
			suscriptos = append(suscriptos, solicitud)
			if len(suscriptos) == 3{
				canalInicio <- Package{}
			}
		case paquete := <- canalConStreamer:
			for i:= range suscriptos{
				suscriptos[i] <- paquete
			}
		}
	}
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

func suscriptor(canalConPlataforma chan chan Package){
	var canalParaRecibirActualizaciones chan Package = make(chan Package)
	canalConPlataforma <- canalParaRecibirActualizaciones
	for{
		paquete := <- canalParaRecibirActualizaciones
		print(paquete.contenido)
	}
}