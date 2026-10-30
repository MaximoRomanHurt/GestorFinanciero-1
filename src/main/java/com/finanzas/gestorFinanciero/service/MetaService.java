/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package com.finanzas.gestorFinanciero.service;

import com.finanzas.gestorFinanciero.dto.MetaFila;
import com.finanzas.gestorFinanciero.dto.MetaForm;
import com.finanzas.gestorFinanciero.model.AporteMeta;
import com.finanzas.gestorFinanciero.model.Categorias.EstadoMeta;
import com.finanzas.gestorFinanciero.model.Categorias.TipoMeta;
import com.finanzas.gestorFinanciero.model.Cliente;
import com.finanzas.gestorFinanciero.model.Cuenta;
import com.finanzas.gestorFinanciero.model.Meta;
import com.finanzas.gestorFinanciero.repository.*;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import java.math.BigDecimal;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
import java.util.Objects;
import java.util.Set;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataAccessException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 *
 * @author adris
 */
@Service
public class MetaService {
    @Autowired
    private final MetaRepository metaRepo;
    private final TipoMetaRepository tipoMetaRepo;
    private final EstadoMetaRepository estadoMetaRepo;
    private final ClienteRepository clienteRepo;
    private final AporteMetaRepository aporteRepo;
    private final CuentaRepository cuentaRepo;
    private final CuentaService cuentaService;
    private static final Long ESTADO_PROGRESO = 1L;
    private static final Long ESTADO_COMPLETADA = 2L;
    private static final Long ESTADO_VENCIDA= 3L;
    private static final Long ESTADO_ANULADA = 4L;
    //Vencimiento de metas
    @PersistenceContext
    private EntityManager em;

    public MetaService(MetaRepository metaRepo, TipoMetaRepository tipoMetaRepo, EstadoMetaRepository estadoMetaRepo, ClienteRepository clienteRepo, AporteMetaRepository aporteRepo, CuentaRepository cuentaRepo, CuentaService cuentaService) {
        this.metaRepo = metaRepo;
        this.tipoMetaRepo = tipoMetaRepo;
        this.estadoMetaRepo = estadoMetaRepo;
        this.clienteRepo = clienteRepo;
        this.aporteRepo = aporteRepo;
        this.cuentaRepo = cuentaRepo;
        this.cuentaService = cuentaService;
    }
    
    @Transactional(readOnly = true)
    public List<MetaFila> listar(Long codCliente) {
        Set<Long> conAportes = aporteRepo.idsMetasConAportes(codCliente);
        Set<Long> saldoRetirado = metaRepo.idsMetasConSaldoRetirado(codCliente);
        return metaRepo.listarPorCliente(codCliente).stream()
                .map(m -> new MetaFila(m, conAportes.contains(m.getId()), saldoRetirado.contains(m.getId())))
                .toList();
    }

    @Transactional(readOnly = true)
    public List<MetaFila> listarPorEstado(Long codCliente, Long idEstado) {
        Set<Long> conAportes = aporteRepo.idsMetasConAportes(codCliente);
        Set<Long> saldoRetirado = metaRepo.idsMetasConSaldoRetirado(codCliente);
        return metaRepo.listarPorClienteYEstado(codCliente, idEstado).stream()
                .map(m -> new MetaFila(m, conAportes.contains(m.getId()), saldoRetirado.contains(m.getId())))
                .toList();
    }
    
    @Transactional(readOnly = true)
    public List<Meta> listarAportables(Long codCliente) {
        return metaRepo.listarPorClienteYEstado(codCliente, ESTADO_PROGRESO).stream()
                .filter(m -> !m.getFechaLimite().isBefore(hoy()))   
                .toList();
    }
    
    @Transactional(readOnly = true)
    public List<Meta> listarRetirables(Long codCliente) {
        return metaRepo.listarPorCliente(codCliente).stream()
                .filter(m -> !Objects.equals(m.getEstado().getId(), ESTADO_ANULADA))
                .toList();
    }
        
    @Transactional
    public Meta crear(MetaForm form, Long codCliente) {
        Cliente cliente= clienteRepo.findById(codCliente)
                .orElseThrow(()-> new NegocioException("El cliente no existe"));
        
        TipoMeta tipoMeta= tipoMetaRepo.findById(form.getIdTipo())
                .orElseThrow(()->new NegocioException("El tipo de meta no existe"));
        
        EstadoMeta estadoMeta= estadoMetaRepo.findById(ESTADO_PROGRESO)
                .orElseThrow(() -> new NegocioException("Estado no encontrado"));
        
        validarMonto(form.getMontoObjetivo());
        
        if (form.getFechaLimite() == null || !form.getFechaLimite().isAfter(hoy())) {
            throw new NegocioException("La fecha límite debe ser posterior a hoy.");
        }
        
        try{        
            Meta meta= new Meta();
            meta.setNombreMeta(form.getNombreMeta());
            meta.setMontoObjetivo(form.getMontoObjetivo());
            meta.setCliente(cliente);
            meta.setFechaLimite(form.getFechaLimite());
            meta.setTipo(tipoMeta);
            meta.setSaldo(BigDecimal.ZERO);
            meta.setEstado(estadoMeta);
            return metaRepo.save(meta);        
        } catch (DataAccessException ex) {
            throw traducir(ex);              
        }
    }
    
    @Transactional
    public void eliminar(Long id, Long codCliente) {
        Meta meta = metaDelCliente(id, codCliente);

        if (aporteRepo.existsByMetaId(id)) {
            if (meta.getSaldo().signum() != 0) {
                throw new NegocioException("La meta todavía tiene dinero reservado. Anule la meta o retire el saldo manualmente");
            }
            
            try {
                aporteRepo.borrarPorMetaYTipo(id, 'R');   
                aporteRepo.borrarPorMetaYTipo(id, 'A');   
            } catch (DataAccessException ex) {
                throw traducir(ex);
            }
        }
        metaRepo.deleteById(id);
    }

    @Transactional
    public void anular(Long id, Long idCuenta, Long codCliente) {
        Meta meta = metaDelCliente(id, codCliente);
        Long estadoId = meta.getEstado().getId();
        
        if (!Objects.equals(estadoId, ESTADO_PROGRESO) && !Objects.equals(estadoId, ESTADO_VENCIDA)){
            throw new NegocioException("Solo se pueden anular metas en progreso o vencidas");
        }

        if (meta.getSaldo().signum() > 0) {
            if (idCuenta == null) {
                throw new NegocioException("Elige la cuenta donde se devolverá el dinero");
            }
            retirar(new AporteCommand(id, idCuenta, meta.getSaldo(), LocalDate.now()), codCliente);
        }

        meta.setEstado(estadoMetaRepo.findById(ESTADO_ANULADA)
                .orElseThrow(() -> new NegocioException("Estado no encontrado")));
        
        metaRepo.save(meta);
    }    
    
    @Transactional (readOnly=true)
    public Meta obtener(Long id, Long codCliente) {
        return metaDelCliente(id, codCliente);
    }

    @Transactional
    public Meta actualizar(Long id, MetaForm form, Long codCliente) {
        Meta m= metaDelCliente(id,codCliente);
        validarMonto(form.getMontoObjetivo());
        
        LocalDate fechaLimite = (form.getFechaLimite().isAfter(hoy())) ? form.getFechaLimite() : null ;
        
        TipoMeta tipoMeta= tipoMetaRepo.findById(form.getIdTipo())
                .orElseThrow(()->new NegocioException("El tipo de meta no existe."));
        
        if (fechaLimite==null) throw new NegocioException("La fecha limite debe ser posterior a hoy.");
        
        if (form.getMontoObjetivo().compareTo(m.getSaldo()) < 0) {
            throw new NegocioException("El monto objetivo no puede ser menor al saldo ya reservado (S/ "
                    + m.getSaldo() + ").");
        }
        
        if (!Objects.equals(m.getEstado().getId(), ESTADO_COMPLETADA)){
            Long nuevo = (m.getSaldo().compareTo(form.getMontoObjetivo()) >= 0)
                    ? ESTADO_COMPLETADA : ESTADO_PROGRESO;
            m.setEstado(estadoMetaRepo.findById(nuevo)
                    .orElseThrow(() -> new NegocioException("Estado no encontrado")));
        }
        
        try{
            m.setFechaLimite(form.getFechaLimite());
            m.setMontoObjetivo(form.getMontoObjetivo());
            m.setNombreMeta(form.getNombreMeta());
            m.setTipo(tipoMeta);  
            return metaRepo.saveAndFlush(m);
        } catch (DataAccessException ex){
            throw traducir(ex);
        }
    }

    @Transactional
    public void aportar(AporteCommand cmd, Long codCliente) {
        validarMonto(cmd.monto());

        Meta meta = metaDelCliente(cmd.idMeta(), codCliente);
        if (meta.getEstado().getId() != 1) {
            throw new NegocioException("Solo puedes aportar a metas en progreso");
        }

        Cuenta cuenta = cuentaService.cuentaDelCliente(cmd.idCuenta(), codCliente);
        if (cuenta.getSaldo().compareTo(cmd.monto()) < 0) {
            throw new NegocioException("Saldo insuficiente en " + cuenta.getNombreCuenta());
        }
        
        if(meta.getFechaLimite().isBefore(cmd.fecha())){
            throw new NegocioException("No se puede aportar a una meta vencida");
        }
        
        BigDecimal nuevoSaldoMeta= meta.getSaldo().add(cmd.monto());
        
        if (meta.getMontoObjetivo().compareTo(nuevoSaldoMeta) < 0) {
            BigDecimal exceso= nuevoSaldoMeta.subtract(meta.getMontoObjetivo());
            throw new NegocioException("El saldo acumulado no puede superar al monto objetivo. Exceso: " + exceso);
        }        
        
        try {
            cuenta.setSaldo(cuenta.getSaldo().subtract(cmd.monto()));
            cuentaRepo.save(cuenta);
            
            meta.setSaldo(nuevoSaldoMeta);
            if (nuevoSaldoMeta.compareTo(meta.getMontoObjetivo()) == 0) {
                meta.setEstado(estadoMetaRepo.findById(ESTADO_COMPLETADA)
                        .orElseThrow(() -> new NegocioException("Estado no encontrado")));
            }            
            metaRepo.save(meta);
            
            AporteMeta aporte = new AporteMeta();
            aporte.setMeta(meta);
            aporte.setCuenta(cuenta);
            aporte.setMonto(cmd.monto());
            aporte.setFecha(cmd.fecha());
            aporte.setTipo('A');
            aporteRepo.saveAndFlush(aporte);   
        } catch (DataAccessException ex) {
            throw traducir(ex);              
        }
    }
   
    @Transactional
    public void retirar(AporteCommand cmd, Long codCliente) {
        validarMonto(cmd.monto());

        Meta meta = metaDelCliente(cmd.idMeta(), codCliente);
        
        if (Objects.equals(meta.getEstado().getId(), ESTADO_ANULADA)) {
            throw new NegocioException("No se puede retirar de una meta cancelada");
        }
        
        if (meta.getSaldo().signum() <= 0) {            
            throw new NegocioException("No hay saldo por retirar en la meta");
        }    
        
        if (meta.getSaldo().compareTo(cmd.monto()) < 0) {
            throw new NegocioException("La meta solo tiene S/ " + meta.getSaldo() + " disponible");
        }
        
        BigDecimal nuevoSaldoMeta= meta.getSaldo().subtract(cmd.monto());
        
        Cuenta cuenta = cuentaService.cuentaDelCliente(cmd.idCuenta(), codCliente);
        try {
            cuenta.setSaldo(cuenta.getSaldo().add(cmd.monto()));
            cuentaRepo.save(cuenta);
            
            meta.setSaldo(nuevoSaldoMeta);
            metaRepo.save(meta);
            
            AporteMeta retiro = new AporteMeta();
            retiro.setMeta(meta);
            retiro.setCuenta(cuenta);
            retiro.setMonto(cmd.monto());
            retiro.setFecha(cmd.fecha());
            retiro.setTipo('R');
            aporteRepo.saveAndFlush(retiro);   
        } catch (DataAccessException ex) {
            throw traducir(ex);              
        }
    }
    
    @Transactional
    public void vencerMetas() {
        em.createNativeQuery("CALL sp_vencer_metas()").executeUpdate();
    }
    
    private void validarMonto(BigDecimal monto) {
        if (monto == null || monto.compareTo(BigDecimal.ZERO) <= 0) {
            throw new NegocioException("El monto debe ser mayor a 0");
        }
    }
    
    private NegocioException traducir(DataAccessException ex) {
        Throwable t = ex.getMostSpecificCause();
        if (t instanceof SQLException sql) {
            boolean isOracleCustom = sql.getErrorCode() >= 20000 && sql.getErrorCode() <= 20999;
            boolean isPostgresCustom = "P0001".equals(sql.getSQLState());
            if (isOracleCustom || isPostgresCustom) {
                String msg = sql.getMessage().split("\n")[0]
                        .replaceFirst("^(?i)(?:ERROR:\\s*|ORA-\\d+:\\s*)", "")
                        .trim();
                return new NegocioException(msg);
            }
        }
        throw ex;
    }
    
    private Meta metaDelCliente(Long id, Long codCliente) {
        Meta m= metaRepo.findByIdWithLock(id)
                .orElseThrow(()->new NegocioException("La meta no existe"));
        if(!m.getCliente().getCodCliente().equals(codCliente)){
            throw new NegocioException("La meta no existe");
        }
        return m;
    }

    private LocalDate hoy() { return LocalDate.now(ZoneId.of("America/Lima")); }
}
