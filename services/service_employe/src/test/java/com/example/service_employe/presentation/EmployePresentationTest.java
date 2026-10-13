package com.example.service_employe.presentation;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.util.List;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.example.service_employe.application.Employe;
import com.example.service_employe.application.EmployeService;

// On vérifie que la couche présentation choisit la bonne méthode du service et renvoie des DTO
@ExtendWith(MockitoExtension.class)
class EmployePresentationTest {

    @Mock
    private EmployeService service;

    @InjectMocks
    private EmployePresentation presentation;

    @Test
    void getEmployes_sansFiltre_retourneTousLesEmployes() {
        when(service.getEmployes()).thenReturn(List.of(new Employe(1, "Alice")));

        List<EmployeDTO> resultat = presentation.getEmployes(List.of());

        assertThat(resultat).extracting(EmployeDTO::getNom).containsExactly("Alice");
        verify(service, never()).getEmployesByIds(anyList());
    }

    @Test
    void getEmployes_avecIds_filtreParIds() {
        when(service.getEmployesByIds(List.of(2))).thenReturn(List.of(new Employe(2, "Bob")));

        List<EmployeDTO> resultat = presentation.getEmployes(List.of(2));

        assertThat(resultat).extracting(EmployeDTO::getId).containsExactly(2);
        verify(service, never()).getEmployes();
    }

    @Test
    void creationEmploye_transmetLEmployeMappeAuService() {
        presentation.creationEmploye(new CreationEmployeDTO(0, "Alice", List.of()));

        // ArgumentCaptor récupère l'objet réellement passé au service pour l'inspecter
        ArgumentCaptor<Employe> captor = ArgumentCaptor.forClass(Employe.class);
        verify(service).creationEmploye(captor.capture());
        assertThat(captor.getValue().getNom()).isEqualTo("Alice");
    }
}
